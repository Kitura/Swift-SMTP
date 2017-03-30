/**
 * Copyright IBM Corporation 2017
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

import Foundation
import Socket
import SSLService

#if os(Linux)
    import Dispatch
#endif

enum Proto: Port {
    case plain = 25
    case plainAlt = 2525
    case tls = 587
    case ssl = 465
}

typealias LoginCallback = ((SMTPSocket, Error?) -> Void)

class SMTPLogin {
    private let hostname: String
    private let user: String
    private let password: String
    private let port: Port?
    private let secure: Bool
    private let authMethods: [AuthMethod]
    private let domainName: String
    private let accessToken: String?
    private let callback: LoginCallback
    
    private let group = DispatchGroup()
    private let loginQueue = DispatchQueue(label: "com.ibm.Kitura-SMTP.SMTPLogin.loginQueue", attributes: .concurrent)
    private let statusQueue = DispatchQueue(label: "com.ibm.Kitura-SMTP.SMTPLogin.statusQueue")
    private var done = false
    private var error: Error
    private let timeout = 10
    
    init(hostname: String, user: String, password: String, port: Port?, secure: Bool, authMethods: [AuthMethod], domainName: String, accessToken: String?, callback: @escaping LoginCallback) {
        self.hostname = hostname
        self.user = user
        self.password = password
        self.port = port
        self.secure = secure
        self.authMethods = authMethods
        self.domainName = domainName
        self.accessToken = accessToken
        self.callback = callback
        error = SMTPError(.couldNotConnectToServer(hostname, timeout))
    }
    
    func login() {
        group.enter()
        
        loginQueue.async {
            self.loginPorts(ports: self.getPorts(port: self.port))
        }
        
        if group.wait(timeout: DispatchTime.now() + .seconds(timeout)) == .timedOut {
            callback(try! SMTPSocket(), error)
        }
    }
    
    private func loginPorts(ports: [Port]) {
        for port in ports {
            loginQueue.async {
                self.loginPort(port: port)
            }
        }
    }
    
    private func loginPort(port: Port) {
        SMTPLoginHelper(hostname: self.hostname, user: self.user, password: self.password, port: port, secure: self.secure, authMethods: self.authMethods, domainName: self.domainName, accessToken: self.accessToken).login(callback: { (socket, err) in
            
            self.statusQueue.sync(flags: .barrier) {
                if !self.done {
                    
                    if let err = err as? SMTPError {
                        if case .badResponse = err {
                            self.done = true
                            self.group.leave()
                            self.callback(socket, err)
                            return
                        }
                    }
                    
                    if let err = err {
                        self.error = err
                        return
                    }
                    
                    self.done = true
                    self.group.leave()
                    self.callback(socket, nil)
                }
            }
        })
    }
    
    private func getPorts(port: Port?) -> [Port] {
        var ports = [Proto.plain.rawValue, Proto.plainAlt.rawValue, Proto.tls.rawValue]
        
        if let port = port {
            if !ports.contains(port) {
                ports.append(port)
            }
        }
        
        return ports
    }
}

class SMTPLoginHelper {
    fileprivate let hostname: String
    fileprivate let user: String
    fileprivate let password: String
    fileprivate let port: Port
    fileprivate let secure: Bool
    fileprivate let authMethods: [AuthMethod]
    fileprivate let domainName: String
    fileprivate let accessToken: String?
    fileprivate var socket: SMTPSocket
    
    init(hostname: String, user: String, password: String, port: Port, secure: Bool, authMethods: [AuthMethod], domainName: String, accessToken: String?) {
        self.hostname = hostname
        self.user = user
        self.password = password
        self.port = port
        self.secure = secure
        self.authMethods = authMethods
        self.domainName = domainName
        self.accessToken = accessToken
        socket = try! SMTPSocket()
    }
    
    func login(callback: LoginCallback) {
        do {
            try connect(port)
            try login()
            callback(socket, nil)
        } catch {
            callback(socket, error)
        }
    }
}

private extension SMTPLoginHelper {
    func connect(_ port: Port) throws {
        try self.socket.socket.connect(to: hostname, port: port)
        _ = try SMTPSocket.parseResponses(try socket.readFromSocket(), command: .connect)
    }
    
    func login() throws {
        var serverInfo = try getServerInfo()
        if try secure && starttls(serverInfo) {
            serverInfo = try starttls()
        }
        switch try getAuthMethod(serverInfo) {
        case .cramMD5: try loginCramMD5()
        case .login: try loginLogin()
        case .plain: try loginPlain()
        case .xoauth2: try loginXOAuth2()
        }
    }
    
    private func getServerInfo() throws -> [SMTPResponse] {
        do { return try ehlo() }
        catch { return try helo() }
    }
    
    private func starttls(_ serverInfo: [SMTPResponse]) throws -> Bool {
        for res in serverInfo {
            let resArr = res.message.components(separatedBy: " ")
            if resArr.first == "STARTTLS" {
                return true
            }
        }
        return false
    }
    
    private func starttls() throws -> [SMTPResponse] {
        let _: Void = try starttls()
        socket.close()
        
        let root = #file
            .characters
            .split(separator: "/", omittingEmptySubsequences: false)
            .dropLast(1)
            .map { String($0) }
            .joined(separator: "/")
        
        #if os(Linux)
            let cert = root + "/cert.pem"
            let key = root + "/key.pem"
            let config = SSLService.Configuration(withCACertificateFilePath: nil, usingCertificateFile: cert, withKeyFile: key, usingSelfSignedCerts: true)
        #else
            let chainFilePath = root + "/cert.pfx"
            let chainFilePassword = "kitura"
            let selfSignedCerts = true
            let config = SSLService.Configuration(withChainFilePath: chainFilePath, withPassword: chainFilePassword, usingSelfSignedCerts: selfSignedCerts)
        #endif
        
        let delegate = try SSLService(usingConfiguration: config)
        socket = try SMTPSocket()
        socket.socket.delegate = delegate
        try connect(Proto.ssl.rawValue)
        
        return try getServerInfo()
    }
    
    private func getAuthMethod(_ serverInfo: [SMTPResponse]) throws -> AuthMethod {
        for res in serverInfo {
            let resArr = res.message.components(separatedBy: " ")
            if resArr.first == "AUTH" {
                let args = resArr.dropFirst()
                for arg in args {
                    if let authMethod = AuthMethod(rawValue: arg), authMethods.contains(authMethod) {
                        return authMethod
                    }
                }
            }
        }
        throw SMTPError(.noSupportedAuthMethods(hostname))
    }
    
    private func loginCramMD5() throws {
        let challenge = try auth(authMethod: .cramMD5, credentials: nil).message
        try authPassword(password: try AuthCredentials.cramMD5(challenge: challenge, user: user, password: password))
    }
    
    private func loginLogin() throws {
        _ = try auth(authMethod: .login, credentials: nil)
        let credentials = AuthCredentials.login(user: user, password: password)
        try authUser(user: credentials.encodedUser)
        try authPassword(password: credentials.encodedPassword)
    }
    
    private func loginPlain() throws {
        _ = try auth(authMethod: .plain, credentials: AuthCredentials.plain(user: user, password: password))
    }
    
    private func loginXOAuth2() throws {
        guard let accessToken = accessToken else {
            throw SMTPError(.noAccessToken)
        }
        _ = try auth(authMethod: .xoauth2, credentials: AuthCredentials.xoauth2(user: user, accessToken: accessToken))
    }
}

private extension SMTPLoginHelper {
    func ehlo() throws -> [SMTPResponse] {
        return try socket.send(.ehlo(domainName))
    }
    
    func helo() throws -> [SMTPResponse] {
        return try socket.send(.helo(domainName))
    }
    
    func starttls() throws {
        return try socket.send(.starttls)
    }
    
    func auth(authMethod: AuthMethod, credentials: String?) throws -> SMTPResponse {
        return try socket.send(.auth(authMethod, credentials))
    }
    
    func authUser(user: String) throws {
        return try socket.send(.authUser(user))
    }
    
    func authPassword(password: String) throws {
        return try socket.send(.authPassword(password))
    }
}
