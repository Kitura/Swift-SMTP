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

enum LoginResult {
    case success(SMTPSocket)
    case failure(Error)
}

typealias LoginCallback = ((LoginResult) -> Void)

class Login {
    fileprivate let hostname: String
    fileprivate let email: String
    fileprivate let password: String
    fileprivate let port: Port
    fileprivate let ssl: SSL?
    fileprivate let authMethods: [AuthMethod]
    fileprivate let domainName: String
    fileprivate let accessToken: String?
    fileprivate let timeout: UInt
    fileprivate var callback: LoginCallback
    fileprivate var socket: SMTPSocket

    init(hostname: String,
         email: String,
         password: String,
         port: Port,
         ssl: SSL?,
         authMethods: [AuthMethod],
         domainName: String,
         accessToken: String?,
         timeout: UInt,
         callback: @escaping LoginCallback) throws {
        self.hostname = hostname
        self.email = email
        self.password = password
        self.port = port
        self.ssl = ssl
        self.authMethods = authMethods
        self.domainName = domainName
        self.accessToken = accessToken
        self.timeout = timeout * 1000
        self.callback = callback
        socket = try SMTPSocket()
    }

    func login() {
        do {
            try connect(port)
            try loginToServer()
            callback(.success(socket))
        } catch {
            callback(.failure(error))
        }
    }
}

private extension Login {
    func connect(_ port: Port) throws {
        try socket.connect(to: hostname, port: port, timeout: timeout)
        try SMTPSocket.parseResponses(try socket.readFromSocket(), command: .connect)
    }

    func loginToServer() throws {
        var serverInfo = try getServerInfo()

        if doesStarttls(serverInfo) {
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

    func starttls(_ ssl: SSL?) throws {
        try starttls()
        socket.close()
        socket = try SMTPSocket()
        if let ssl = ssl {
            socket.setDelegate(try ssl.makeSSLService())
        } else {
            socket.setDelegate(try SSL().makeSSLService())
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
        throw SMTPError(.noSupportedAuthMethods(hostname: hostname))
    }
}

private extension Login {
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
        try auth(authMethod: .plain,
                 credentials: AuthEncoder.plain(user: email, password: password))
    }

    func loginXOAuth2() throws {
        guard let accessToken = accessToken else {
            throw SMTPError(.noAccessToken)
        }
        try auth(authMethod: .xoauth2, credentials: AuthEncoder.xoauth2(user: email, accessToken: accessToken))
    }
}

private extension Login {
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
        let response = try socket.send(.auth(authMethod, credentials))
        guard response.count == 1 else {
            throw SMTPError(.badResponse(command: "AUTH", response: response.description))
        }
        return response[0]
    }

    func authUser(_ user: String) throws {
        try socket.send(.authUser(user))
    }

    func authPassword(_ password: String) throws {
        try socket.send(.authPassword(password))
    }
}
