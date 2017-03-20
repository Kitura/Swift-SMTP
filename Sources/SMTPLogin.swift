//
//  SMTPLogin.swift
//  KituraSMTP
//
//  Created by Quan Vo on 3/16/17.
//
//

import Foundation
import Socket
import SSLService

class SMTPLogin {
    fileprivate let hostname: String
    fileprivate let user: String
    fileprivate let password: String
    fileprivate let accessToken: String?
    fileprivate let domainName: String
    fileprivate let authMethods: [AuthMethod]
    fileprivate let chainFilePath: String?
    fileprivate let chainFilePassword: String?
    fileprivate let selfSignedCerts: Bool?
    fileprivate var socket: SMTPSocket
    
    init(config: SMTPConfig, socket: SMTPSocket) {
        hostname = config.hostname
        user = config.user
        password = config.password
        accessToken = config.accessToken
        domainName = config.domainName
        authMethods = config.authMethods
        chainFilePath = config.chainFilePath
        chainFilePassword = config.chainFilePassword
        selfSignedCerts = config.selfSignedCerts
        self.socket = socket
    }
    
    func login() throws -> SMTPSocket {
        try connect(Port.tls)
        let _: Void = try login()
        return socket
    }
}

public enum AuthMethod: String {
    case cramMD5 = "CRAM-MD5"
    case login = "LOGIN"
    case plain = "PLAIN"
    case xoauth2 = "XOAUTH2"
    
    static let defaultAuthMethods: [AuthMethod] = [.cramMD5, .login, .plain, .xoauth2]
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
    
    private func starttls(_ serverInfo: [SMTPResponse]) throws -> AuthMethod {
        for res in serverInfo {
            let resArr = res.message.components(separatedBy: " ")
            if resArr.first == "STARTTLS" {
                return try starttls()
            }
        }
        return try getAuthMethod(serverInfo)
    }
    
    private func starttls() throws -> AuthMethod {
        guard let chainFilePath = chainFilePath, let chainFilePassword = chainFilePassword, let selfSignedCerts = selfSignedCerts else {
            throw SMTPError(.certChainFileInfoMissing(hostname))
        }
        
        let _: Void = try starttls()
        
        let config = SSLService.Configuration(withChainFilePath: chainFilePath, withPassword: chainFilePassword, usingSelfSignedCerts: selfSignedCerts)
        let newSocket = try SMTPSocket()
        newSocket.socket.delegate = try SSLService(usingConfiguration: config)
        socket.socket.close()
        socket = newSocket
        try connect(Port.ssl)
        
        return try getAuthMethod(try getServerInfo())
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
