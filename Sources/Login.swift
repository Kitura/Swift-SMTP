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

typealias LoginCallback = ((SMTPSocket?, Error?) -> Void)

struct Login {
    private let hostname: String
    private let user: String
    private let password: String
    private let port: Port
    private let ssl: SSL?
    private let authMethods: [AuthMethod]
    private let domainName: String
    private let accessToken: String?
    private let timeout: Int
    private let callback: LoginCallback

    init(hostname: String, user: String, password: String, port: Port, ssl: SSL?, authMethods: [AuthMethod], domainName: String, accessToken: String?, timeout: Int, callback: @escaping LoginCallback) {
        self.hostname = hostname
        self.user = user
        self.password = password
        self.port = port
        self.ssl = ssl
        self.authMethods = authMethods
        self.domainName = domainName
        self.accessToken = accessToken
        self.timeout = timeout
        self.callback = callback
    }

    func login() {
        let queue = DispatchQueue(label: "com.ibm.Kitura-SMTP.Login.queue", attributes: .concurrent)
        queue.async {

            let group = DispatchGroup()
            group.enter()

            // Yet another thread is created here because trying to connect on a
            // "bad" port will hang that thread. Doing this on a separate one
            // ensures we can call `wait` and timeout if needed.
            queue.async {
                do {
                    try LoginHelper(hostname: self.hostname, user: self.user, password: self.password, port: self.port, ssl: self.ssl, authMethods: self.authMethods, domainName: self.domainName, accessToken: self.accessToken).login { (socket, err) in
                        group.leave()
                        self.callback(socket, err)
                    }
                } catch {
                    group.leave()
                    self.callback(nil, error)
                }
            }

            if group.wait(timeout: DispatchTime.now() + .seconds(self.timeout)) == .timedOut {
                self.callback(nil, SMTPError(.couldNotConnectToServer(self.hostname, self.timeout)))
            }
        }
    }
}

private class LoginHelper {
    let hostname: String
    let user: String
    let password: String
    let port: Port
    let ssl: SSL?
    let authMethods: [AuthMethod]
    let domainName: String
    let accessToken: String?
    var socket: SMTPSocket

    init(hostname: String, user: String, password: String, port: Port, ssl: SSL?, authMethods: [AuthMethod], domainName: String, accessToken: String?) throws {
        self.hostname = hostname
        self.user = user
        self.password = password
        self.port = port
        self.ssl = ssl
        self.authMethods = authMethods
        self.domainName = domainName
        self.accessToken = accessToken
        socket = try SMTPSocket()
    }

    func login(callback: LoginCallback) {
        do {
            try connect(port)
            try login()
            callback(socket, nil)
        } catch {
            callback(nil, error)
        }
    }
}

private extension LoginHelper {
    func connect(_ port: Port) throws {
        try socket.connect(to: hostname, port: port)
        _ = try SMTPSocket.parseResponses(try socket.readFromSocket(), command: .connect)
    }
}

private extension LoginHelper {
    func login() throws {
        var serverInfo = try getServerInfo()

        if let ssl = ssl, doesStarttls(serverInfo) {
            try starttls(ssl)
            try connect(Ports.ssl.rawValue)
            serverInfo = try getServerInfo()
        }

        switch try getAuthMethod(serverInfo) {
        case .cramMD5: try loginCramMD5()
        case .login: try loginLogin()
        case .plain: try loginPlain()
        case .xoauth2: try loginXOAuth2()
        }
    }

    func getServerInfo() throws -> [Response] {
        do {
            return try ehlo()
        } catch {
            return try helo()
        }
    }

    func doesStarttls(_ serverInfo: [Response]) -> Bool {
        return serverInfo.contains { $0.message.contains("STARTTLS") }
    }

    func starttls(_ ssl: SSL) throws {
        try starttls()
        socket.close()
        socket = try SMTPSocket()

        var config: SSLService.Configuration

        // Only `.caCertificateDirectory` on Linux and `.chainFile` on macOS
        // have been tested.
        #if os(Linux)
            switch ssl.config {
            case .caCertificatePath(ca: let c):
                config = SSLService.Configuration(withCACertificateFilePath: c.ca, usingCertificateFile: c.cert, withKeyFile: c.key, usingSelfSignedCerts: c.selfSigned, cipherSuite: c.cipher)

            case .caCertificateDirectory(ca: let c):
                config = SSLService.Configuration(withCACertificateDirectory: c.ca, usingCertificateFile: c.cert, withKeyFile: c.key, usingSelfSignedCerts: c.selfSigned, cipherSuite: c.cipher)

            case .pemCertificate(pem: let c):
                config = SSLService.Configuration(withPEMCertificateString: c.pem, usingSelfSignedCerts: c.selfSigned, cipherSuite: c.cipher)

            case .cipherSuite(cipher: let c):
                config = SSLService.Configuration(withCipherSuite: c)

            case .chainFile(let c):
                config = SSLService.Configuration(withChainFilePath: c.chainFilePath, withPassword: c.password, usingSelfSignedCerts: c.selfSigned, cipherSuite: c.cipherSuite)
            }
        #else
            switch ssl.config {
            case .chainFile(let c):
                config = SSLService.Configuration(withChainFilePath: c.chainFilePath, withPassword: c.password, usingSelfSignedCerts: c.selfSigned, cipherSuite: c.cipherSuite)
            }
        #endif

        socket.socket.delegate = try SSLService(usingConfiguration: config)
    }

    func getAuthMethod(_ serverInfo: [Response]) throws -> AuthMethod {
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
}

private extension LoginHelper {
    func loginCramMD5() throws {
        let challenge = try auth(authMethod: .cramMD5, credentials: nil).message
        try authPassword(password: try AuthEncoder.cramMD5(challenge: challenge, user: user, password: password))
    }

    func loginLogin() throws {
        _ = try auth(authMethod: .login, credentials: nil)
        let credentials = AuthEncoder.login(user: user, password: password)
        try authUser(user: credentials.encodedUser)
        try authPassword(password: credentials.encodedPassword)
    }

    func loginPlain() throws {
        _ = try auth(authMethod: .plain, credentials: AuthEncoder.plain(user: user, password: password))
    }

    func loginXOAuth2() throws {
        guard let accessToken = accessToken else {
            throw SMTPError(.noAccessToken)
        }
        _ = try auth(authMethod: .xoauth2, credentials: AuthEncoder.xoauth2(user: user, accessToken: accessToken))
    }
}

private extension LoginHelper {
    func ehlo() throws -> [Response] {
        return try socket.send(.ehlo(domainName))
    }

    func helo() throws -> [Response] {
        return try socket.send(.helo(domainName))
    }

    func starttls() throws {
        return try socket.send(.starttls)
    }

    func auth(authMethod: AuthMethod, credentials: String?) throws -> Response {
        return try socket.send(.auth(authMethod, credentials))
    }

    func authUser(user: String) throws {
        return try socket.send(.authUser(user))
    }

    func authPassword(password: String) throws {
        return try socket.send(.authPassword(password))
    }
}
