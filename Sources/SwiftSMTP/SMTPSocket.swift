/**
 * Copyright IBM Corporation 2018
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
import LoggerAPI

struct SMTPSocket {
    private let socket: Socket

    init(hostname: String,
         email: String,
         password: String,
         port: Int32,
         tlsMode: SMTP.TLSMode,
         tlsConfiguration: TLSConfiguration?,
         authMethods: [String: AuthMethod],
         domainName: String,
         timeout: UInt) throws {
        socket = try Socket.create()
        if tlsMode == .requireTLS {
            if let tlsConfiguration = tlsConfiguration {
                socket.delegate = try tlsConfiguration.makeSSLService()
            } else {
                socket.delegate = try TLSConfiguration().makeSSLService()
            }
        }
        try socket.connect(to: hostname, port: port, timeout: timeout * 1000)
        try parseResponses(readFromSocket(), command: .connect)
        var serverOptions = try getServerOptions(domainName: domainName)
        if tlsMode == .requireSTARTTLS || tlsMode == .normal {
            if try doStarttls(serverOptions: serverOptions, tlsConfiguration: tlsConfiguration) {
                serverOptions = try getServerOptions(domainName: domainName)
            } else if tlsMode == .requireSTARTTLS {
                throw SMTPError.requiredSTARTTLS
            }
        }
        let authMethod = try getAuthMethod(authMethods: authMethods, serverOptions: serverOptions, hostname: hostname)
        try login(authMethod: authMethod, email: email, password: password)
    }

    func write(_ text: String) throws {
        _ = try socket.write(from: text + CRLF)
        Log.debug(text)
    }

    func write(_ data: Data) throws {
        _ = try socket.write(from: data)
        Log.debug("(sending data)")
    }

    @discardableResult
    func send(_ command: Command) throws -> [Response] {
        try write(command.text)
        return try parseResponses(readFromSocket(), command: command)
    }

    func close() {
        socket.close()
    }
}

private extension SMTPSocket {
    func readFromSocket() throws -> String {
        var buf = Data()
        _ = try socket.read(into: &buf)
        guard let responses = String(data: buf, encoding: .utf8) else {
            throw SMTPError.convertDataUTF8Fail(data: buf)
        }
        Log.debug(responses)
        return responses
    }

    @discardableResult
    func parseResponses(_ responses: String, command: Command) throws -> [Response] {
        let responsesArray = responses.components(separatedBy: CRLF)
        guard !responsesArray.isEmpty else {
            throw SMTPError.badResponse(command: command.text, response: responses)
        }
        #if swift(>=4.1)
        return try responsesArray.compactMap { response in
            guard response != "" else {
                return nil
            }
            return Response(
                code: try getResponseCode(response, command: command),
                message: getResponseMessage(response),
                response: response
            )
        }
        #else
        return try responsesArray.flatMap { response in
            guard response != "" else {
                return nil
            }
            return Response(
                code: try getResponseCode(response, command: command),
                message: getResponseMessage(response),
                response: response
            )
        }
        #endif
    }

    func getResponseCode(_ response: String, command: Command) throws -> ResponseCode {
        guard response.count > 3 else {
            throw SMTPError.badResponse(command: command.text, response: response)
        }
        guard let code = Int(response[..<response.index(response.startIndex, offsetBy: 3)]) else {
            throw SMTPError.badResponse(command: command.text, response: response)
        }
        guard
            response.count > 2,
            command.expectedResponseCodes.map({ $0.rawValue }).contains(code) else {
                throw SMTPError.badResponse(command: command.text, response: response)
        }
        return ResponseCode(code)
    }

    func getResponseMessage(_ response: String) -> String {
        guard response.count > 3 else {
            return ""
        }
        return String(response[response.index(response.startIndex, offsetBy: 4)...])
    }
}

private extension SMTPSocket {
    func getServerOptions(domainName: String) throws -> [Response] {
        do {
            return try send(.ehlo(domainName))
        } catch {
            return try send(.helo(domainName))
        }
    }

    func getAuthMethod(authMethods: [String: AuthMethod], serverOptions: [Response], hostname: String) throws -> AuthMethod {
        for option in serverOptions {
            let components = option.message.components(separatedBy: " ")
            if components.first == "AUTH" {
                let _authMethods = components.dropFirst()
                for authMethod in _authMethods {
                    if let matchingAuthMethod = authMethods[authMethod] {
                        return matchingAuthMethod
                    }
                }
            }
        }
        throw SMTPError.noAuthMethodsOrRequiresTLS(hostname: hostname)
    }

    func doStarttls(serverOptions: [Response], tlsConfiguration: TLSConfiguration?) throws -> Bool {
        for option in serverOptions {
            if option.message == "STARTTLS" {
                try starttls(tlsConfiguration: tlsConfiguration)
                return true
            }
        }
        return false
    }

    func starttls(tlsConfiguration: TLSConfiguration?) throws {
        try send(.starttls)
        // Upgrade the socket to SSL/TLS
        if let tlsConfiguration = tlsConfiguration {
            socket.delegate = try tlsConfiguration.makeSSLService()
        } else {
            socket.delegate = try TLSConfiguration().makeSSLService()
        }
        try socket.delegate?.initialize(asServer: false)
        try socket.delegate?.onConnect(socket: socket)
    }

    func login(authMethod: AuthMethod, email: String, password: String) throws {
        switch authMethod {
        case .cramMD5:
            try loginCramMD5(email: email, password: password)
        case .login:
            try loginLogin(email: email, password: password)
        case .plain:
            try loginPlain(email: email, password: password)
        case .xoauth2:
            try loginXOAuth2(email: email, accessToken: password)
        }
    }

    func loginCramMD5(email: String, password: String) throws {
        let challenge = try auth(authMethod: .cramMD5, credentials: nil).message
        try authPassword(try AuthEncoder.cramMD5(challenge: challenge, user: email, password: password))
    }

    func loginLogin(email: String, password: String) throws {
        try auth(authMethod: .login, credentials: nil)
        let credentials = AuthEncoder.login(user: email, password: password)
        try authUser(credentials.encodedUser)
        try authPassword(credentials.encodedPassword)
    }

    func loginPlain(email: String, password: String) throws {
        try auth(
            authMethod: .plain,
            credentials: AuthEncoder.plain(user: email, password: password)
        )
    }

    func loginXOAuth2(email: String, accessToken: String) throws {
        try auth(authMethod: .xoauth2, credentials: AuthEncoder.xoauth2(user: email, accessToken: accessToken))
    }

    @discardableResult
    func auth(authMethod: AuthMethod, credentials: String?) throws -> Response {
        let responses = try send(.auth(authMethod, credentials))
        guard let response = responses.first else {
            throw SMTPError.badResponse(command: "AUTH", response: responses.description)
        }
        return response
    }

    func authUser(_ user: String) throws {
        try send(.authUser(user))
    }

    func authPassword(_ password: String) throws {
        try send(.authPassword(password))
    }
}
