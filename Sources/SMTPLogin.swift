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

class SMTPLogin {
    fileprivate let hostname: String
    fileprivate let user: String
    fileprivate let password: String
    fileprivate let accessToken: String?
    fileprivate let domainName: String
    fileprivate let authMethods: [SMTP.AuthMethod]
    fileprivate let chainFilePath: String?
    fileprivate let chainFilePassword: String?
    fileprivate let selfSignedCerts: Bool?
    fileprivate var socket: SMTPSocket
    
    init(hostname: String, user: String, password: String, accessToken: String?, domainName: String, authMethods: [SMTP.AuthMethod], chainFilePath: String?, chainFilePassword: String?, selfSignedCerts: Bool?) throws {
        self.hostname = hostname
        self.user = user
        self.password = password
        self.accessToken = accessToken
        self.domainName = domainName
        self.authMethods = authMethods
        self.chainFilePath = chainFilePath
        self.chainFilePassword = chainFilePassword
        self.selfSignedCerts = selfSignedCerts
        socket = try SMTPSocket()
    }
    
    func login() throws -> SMTPSocket {
        try connect(Port.tls)
        let _: Void = try login()
        return socket
    }
}

private extension SMTPLogin {
    enum Port: Int32 {
        case tls = 587
        case ssl = 465
    }
    
    func connect(_ port: Port) throws {
        try socket.socket.connect(to: hostname, port: port.rawValue)
        _ = try SMTPSocket.parseResponses(try socket.readFromSocket(), command: .connect)
    }
    
    func login() throws {
        switch try starttls(try getServerInfo()) {
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
    
    private func starttls(_ serverInfo: [SMTPResponse]) throws -> SMTP.AuthMethod {
        for res in serverInfo {
            let resArr = res.message.components(separatedBy: " ")
            if resArr.first == "STARTTLS" {
                return try starttls()
            }
        }
        return try getAuthMethod(serverInfo)
    }
    
    private func starttls() throws -> SMTP.AuthMethod {
        guard let chainFilePath = chainFilePath, let chainFilePassword = chainFilePassword, let selfSignedCerts = selfSignedCerts else {
            throw SMTPError(.certChainFileInfoMissing(hostname))
        }
        
        let _: Void = try starttls()
        
        let config = SSLService.Configuration(withChainFilePath: chainFilePath, withPassword: chainFilePassword, usingSelfSignedCerts: selfSignedCerts)
        let newSocket = try SMTPSocket()
        newSocket.socket.delegate = try SSLService(usingConfiguration: config)
        socket.close()
        socket = newSocket
        try connect(Port.ssl)
        
        return try getAuthMethod(try getServerInfo())
    }
    
    private func getAuthMethod(_ serverInfo: [SMTPResponse]) throws -> SMTP.AuthMethod {
        for res in serverInfo {
            let resArr = res.message.components(separatedBy: " ")
            if resArr.first == "AUTH" {
                let args = resArr.dropFirst()
                for arg in args {
                    if let authMethod = SMTP.AuthMethod(rawValue: arg), authMethods.contains(authMethod) {
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

private extension SMTPLogin {
    func ehlo() throws -> [SMTPResponse] {
        return try socket.send(.ehlo(domainName))
    }
    
    func helo() throws -> [SMTPResponse] {
        return try socket.send(.helo(domainName))
    }
    
    func starttls() throws {
        return try socket.send(.starttls)
    }
    
    func auth(authMethod: SMTP.AuthMethod, credentials: String?) throws -> SMTPResponse {
        return try socket.send(.auth(authMethod, credentials))
    }
    
    func authUser(user: String) throws {
        return try socket.send(.authUser(user))
    }
    
    func authPassword(password: String) throws {
        return try socket.send(.authPassword(password))
    }
}
