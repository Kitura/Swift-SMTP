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

#if os(Linux)
    import Dispatch
#endif

protocol LoginManaging {
    func login(completion: (Result<SMTPSocket, Error>) -> Void)
}

class LoginManager: LoginManaging {
    private let hostname: String
    private let email: String
    private let password: String
    private let port: Int32
    private let useTLS: Bool
    private let tlsConfiguration: TLSConfiguration?
    private let authMethods: [AuthMethod]
    private let accessToken: String?
    private let domainName: String
    private let timeout: UInt
    private var socket: SMTPSocket!

    init(hostname: String,
         email: String,
         password: String,
         port: Int32,
         useTLS: Bool,
         tlsConfiguration: TLSConfiguration?,
         authMethods: [AuthMethod],
         accessToken: String?,
         domainName: String,
         timeout: UInt) {
        self.hostname = hostname
        self.email = email
        self.password = password
        self.port = port
        self.useTLS = useTLS
        self.tlsConfiguration = tlsConfiguration
        self.authMethods = authMethods
        self.accessToken = accessToken
        self.domainName = domainName
        self.timeout = timeout * 1000
    }

    func login(completion: (Result<SMTPSocket, Error>) -> Void) {
        do {
            socket = try SMTPSocket()
            if useTLS {
                if let tlsConfiguration = tlsConfiguration {
                    socket.setDelegate(try tlsConfiguration.makeSSLService())
                } else {
                    socket.setDelegate(try TLSConfiguration().makeSSLService())
                }
            }
            try connect(port)
            try login(getServerInfo())
            completion(.success(socket))
        } catch {
            completion(.failure(error))
        }
    }
}

private extension LoginManager {
    func connect(_ port: Int32) throws {
        try socket.connect(to: hostname, port: port, timeout: timeout)
        try SMTPSocket.parseResponses(try socket.readFromSocket(), command: .connect)
    }

    func getServerInfo() throws -> [Response] {
        do {
            return try ehlo()
        } catch {
            return try helo()
        }
    }

    func login(_ serverInfo: [Response]) throws {
        switch try getAuthMethod(serverInfo) {
        case .cramMD5:
            try loginCramMD5()
        case .login:
            try loginLogin()
        case .plain:
            try loginPlain()
        case .xoauth2:
            try loginXOAuth2()
        }
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
        throw SMTPError.noSupportedAuthMethods(hostname: hostname)
    }
}

private extension LoginManager {
    func loginCramMD5() throws {
        let challenge = try auth(authMethod: .cramMD5, credentials: nil).message
        try authPassword(try AuthEncoder.cramMD5(challenge: challenge, user: email, password: password))
    }

    func loginLogin() throws {
        try auth(authMethod: .login, credentials: nil)
        let credentials = AuthEncoder.login(user: email, password: password)
        try authUser(credentials.encodedUser)
        try authPassword(credentials.encodedPassword)
    }

    func loginPlain() throws {
        try auth(
            authMethod: .plain,
            credentials: AuthEncoder.plain(user: email, password: password)
        )
    }

    func loginXOAuth2() throws {
        guard let accessToken = accessToken else {
            throw SMTPError.noAccessToken
        }
        try auth(authMethod: .xoauth2, credentials: AuthEncoder.xoauth2(user: email, accessToken: accessToken))
    }
}

private extension LoginManager {
    func ehlo() throws -> [Response] {
        return try socket.send(.ehlo(domainName))
    }

    func helo() throws -> [Response] {
        return try socket.send(.helo(domainName))
    }

    func starttls() throws {
        try socket.send(.starttls)
    }

    @discardableResult
    func auth(authMethod: AuthMethod, credentials: String?) throws -> Response {
        let responses = try socket.send(.auth(authMethod, credentials))
        guard let response = responses.first else {
            throw SMTPError.badResponse(command: "AUTH", response: responses.description)
        }
        return response
    }

    func authUser(_ user: String) throws {
        try socket.send(.authUser(user))
    }

    func authPassword(_ password: String) throws {
        try socket.send(.authPassword(password))
    }
}
