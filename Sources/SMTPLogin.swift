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
    fileprivate let authMethods: [SMTP.AuthMethod]
    fileprivate let chainFilePath: String?
    fileprivate let chainFilePassword: String?
    fileprivate let selfSignedCerts: Bool?
    fileprivate var socket: SMTPSocket
    fileprivate var loggedIn = false
    
    init(hostname: String, user: String, password: String, accessToken: String?, domainName: String, authMethods: [SMTP.AuthMethod], chainFilePath: String?, chainFilePassword: String?, selfSignedCerts: Bool?, socket: SMTPSocket) {
        self.hostname = hostname
        self.user = user
        self.password = password
        self.accessToken = accessToken
        self.domainName = domainName
        self.authMethods = authMethods
        self.chainFilePath = chainFilePath
        self.chainFilePassword = chainFilePassword
        self.selfSignedCerts = selfSignedCerts
        self.socket = socket
    }
    
    func login() throws -> SMTPSocket {
        if !socket.socket.isConnected {
            try connect(Port.tls)
        }
        if !loggedIn {
            let _: Void = try login()
        }
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
        loggedIn = true
    }
    
    func getServerInfo() throws -> [SMTPResponse] {
        do { return try ehlo() }
        catch { return try helo() }
    }
    
    func starttls(_ serverInfo: [SMTPResponse]) throws -> SMTP.AuthMethod {
        for res in serverInfo {
            let resArr = res.message.components(separatedBy: " ")
            if resArr.first == "STARTTLS" {
                return try starttls()
            }
        }
        return try getAuthMethod(serverInfo)
    }
    
    func starttls() throws -> SMTP.AuthMethod {
        guard let chainFilePath = chainFilePath, let chainFilePassword = chainFilePassword, let selfSignedCerts = selfSignedCerts else {
            throw NSError("\(hostname) offers STARTTLS. SMTP instance must be initialized with a valid Certificate Chain File path in PKCS12 format and password.")
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
    
    func getAuthMethod(_ serverInfo: [SMTPResponse]) throws -> SMTP.AuthMethod {
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
        throw NSError("No supported authorization methods that matched the preferred authorization methods were found on \"\(hostname)\".")
    }
    
    func loginCramMD5() throws {
        let res: SMTPResponse = try auth(authMethod: .cramMD5, credentials: nil)
        let challenge = res.message
        let responseToChallenge = try AuthCredentials.cramMD5(challenge: challenge, user: user, password: password)
        try authPassword(password: responseToChallenge)
    }
    
    func loginLogin() throws {
        let _: Void = try auth(authMethod: .login, credentials: nil)
        let credentials = AuthCredentials.login(user: user, password: password)
        try authUser(user: credentials.encodedUser)
        try authPassword(password: credentials.encodedPassword)
    }
    
    func loginPlain() throws {
        let _: Void = try auth(authMethod: .plain, credentials: AuthCredentials.plain(user: user, password: password))
    }
    
    func loginXOAuth2() throws {
        guard let accessToken = accessToken else {
            throw NSError("Attempted to login using XOAUTH2 but SMTP instance was initialized without an access token.")
        }
        let _: Void = try auth(authMethod: .xoauth2, credentials: AuthCredentials.xoauth2(user: user, accessToken: accessToken))
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
    
    func auth(authMethod: SMTP.AuthMethod, credentials: String?) throws {
        return try socket.send(.auth(authMethod, credentials))
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
