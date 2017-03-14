import Foundation
import Socket
import SSLService

/// Used to connect to an SMTP server and send emails.
public class SMTP {
    let hostname: String
    let user: String
    let password: String
    let domainName: String
    let chainFilePath: String?
    let chainFilePassword: String?
    let selfSignedCerts: Bool?
    fileprivate var socket: Socket
    fileprivate var loggedIn = false
    // TODO: - UUID?
    
    public init(url: String, user: String, password: String, domainName: String = "localhost", chainFilePath: String? = nil, chainFilePassword: String? = nil, selfSignedCerts: Bool? = nil) throws {
        self.hostname = url
        self.user = user
        self.password = password
        self.domainName = domainName
        self.chainFilePath = chainFilePath
        self.chainFilePassword = chainFilePassword
        self.selfSignedCerts = selfSignedCerts
        socket = try Socket.create()
    }
    
    deinit {
        socket.close()
    }
}

// MARK: - Connect to SMTP server
fileprivate extension SMTP {
    typealias Port = Int32
    
    enum SecurityLayer {
        case tls
        case ssl
        
        var port: Port {
            switch self {
            case .tls: return 587
            case .ssl: return 465
            }
        }
    }
    
    // TODO: - Add checks for if SMTP is already trying to connect
    func setup() throws {
        if !socket.isConnected {
            try connect(SecurityLayer.tls.port)
        }
        if !loggedIn {
            try login()
        }
    }
    
    func connect(_ port: Port) throws {
        try socket.connect(to: hostname, port: port)
        _ = try parseResponses(try readFromSocket(), command: .connect)
    }
}

// MARK: - Authentication method for SMTP server
extension SMTP {
    enum AuthMethod: String {
        case cramMD5 = "CRAM-MD5"
        case login = "LOGIN"
        case plain = "PLAIN"
        case xOauth2 = "XOAUTH2"
    }
}

// MARK: - Login to SMTP server
fileprivate extension SMTP {
    func login() throws {
        switch try starttls(try getServerInfo()) {
        case .cramMD5: try loginCramMD5()
        case .login: try loginLogin()
        case .plain: try loginPlain()
        case .xOauth2: try loginXOauth2()
        }
        loggedIn = true
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
            throw NSError("\(hostname) offers STARTTLS. SMTP instance must be initialized with a valid Certificate Chain File path in PKCS12 format and password.")
        }
        
        let _: Void = try starttls()
        
        let config = SSLService.Configuration(withChainFilePath: chainFilePath, withPassword: chainFilePassword, usingSelfSignedCerts: selfSignedCerts)
        let newSocket = try Socket.create()
        newSocket.delegate = try SSLService(usingConfiguration: config)
        socket.close()
        socket = newSocket
        try connect(SecurityLayer.ssl.port)
        
        return try getAuthMethod(try getServerInfo())
    }
    
    private func getAuthMethod(_ serverInfo: [SMTPResponse]) throws -> AuthMethod {
        for res in serverInfo {
            let resArr = res.message.components(separatedBy: " ")
            if resArr.first == "AUTH" {
                let args = resArr.dropFirst()
                for arg in args {
                    switch arg {
                    case "CRAM-MD5": return AuthMethod.cramMD5
                    case "LOGIN": return AuthMethod.login
                    case "PLAIN": return AuthMethod.plain
                    case "XOAUTH2": return AuthMethod.xOauth2
                    default: break
                    }
                }
            }
        }
        throw NSError("No supported authorization methods found on \(hostname).")
    }

    private func loginCramMD5() throws {
        let res: SMTPResponse = try auth(authMethod: .cramMD5, credentials: nil)
        let challenge = res.message
        let responseToChallenge = try AuthCredentials.cramMD5(challenge: challenge, user: user, password: password)
        let _: Void = try auth(authMethod: .cramMD5, credentials: responseToChallenge)
    }

    private func loginLogin() throws {
        let _: Void = try auth(authMethod: .login, credentials: nil)
        let credentials = AuthCredentials.login(user: user, password: password)
        try authUser(user: credentials.encodedUser)
        try authPassword(password: credentials.encodedPassword)
    }
    
    private func loginPlain() throws {
        let _: Void = try auth(authMethod: .plain, credentials: AuthCredentials.plain(user: user, password: password))
    }
    
    private func loginXOauth2() throws {
        let _: Void = try auth(authMethod: .xOauth2, credentials: AuthCredentials.xOauth2(user: user, password: password))
    }
}

// MARK: - Send email
extension SMTP {
    public func send(_ mail: Mail) throws {
        try setup()
        try sendMail(mail.from.email)
        try sendTo(mail.to[0].email)
        try sendData(mail)
    }
    
    private func sendData(_ mail: Mail) throws {
        try data()
        try write("From: \"\(mail.from.name)\" <\(mail.from.email)>")
        try write("To: \"\(mail.to[0].name)\" <\(mail.to[0].email)>")
        let date = Date().toString()
        try write("Date: \(date)")
        try write("Subject: \(mail.subject)")
        try write("")
        try write("\(mail.text)")
        try dataEnd()
    }
}

// MARK: - Send commands to SMTP server
fileprivate extension SMTP {
    func ehlo() throws -> [SMTPResponse] {
        return try send(.ehlo(domainName))
    }
    
    func helo() throws -> [SMTPResponse] {
        return try send(.helo(domainName))
    }
    
    func starttls() throws {
        return try send(.starttls)
    }
    
    func auth(authMethod: AuthMethod, credentials: String?) throws {
        return try send(.auth(authMethod, credentials))
    }
    
    func auth(authMethod: AuthMethod, credentials: String?) throws -> SMTPResponse {
        return try send(.auth(authMethod, credentials))
    }
    
    func authUser(user: String) throws {
        return try send(.authUser(user))
    }
    
    func authPassword(password: String) throws {
        return try send(.authPassword(password))
    }
    
    func help(_ args: String? = nil) throws {
        return try send(.help(args))
    }
    
    func rset() throws {
        return try send(.rset)
    }
    
    func noop() throws {
        return try send(.noop)
    }
    
    func sendMail(_ from: String) throws {
        return try send(.mail(from))
    }
    
    func sendTo(_ to: String) throws {
        return try send(.rcpt(to))
    }
    
    func data() throws {
        return try send(.data)
    }
    
    func dataEnd() throws {
        return try send(.dataEnd)
    }
    
    func vrfy(address: String) throws {
        return try send(.vrfy(address))
    }
    
    func expn(address: String) throws {
        return try send(.expn(address))
    }
    
    func quit() throws {
        defer { socket.close() }
        return try send(.quit)
    }
}

// MARK: - Supporting functions to send commands
fileprivate extension SMTP {
    func send(_ command: SMTPCommand) throws {
        try write(command.text)
        _ = try parseResponses(try readFromSocket(), command: command)
    }
    
    func send(_ command: SMTPCommand) throws -> SMTPResponse {
        try write(command.text)
        return try parseResponses(try readFromSocket(), command: command)[0]
    }
    
    func send(_ command: SMTPCommand) throws -> [SMTPResponse] {
        try write(command.text)
        return try parseResponses(try readFromSocket(), command: command)
    }
    
    func write(_ commandText: String) throws {
        print(commandText)
        _ = try socket.write(from: commandText + CRLF)
    }
    
    func readFromSocket() throws -> String {
        var buf = Data()
        _ = try socket.read(into: &buf)
        guard let res = String(data: buf, encoding: .utf8) else {
            throw NSError("Error converting data to string: \(data).")
        }
        print(res)
        return res
    }
    
    func parseResponses(_ responses: String, command: SMTPCommand) throws -> [SMTPResponse] {
        var validResponses = [SMTPResponse]()
        let resArr = responses.components(separatedBy: CRLF)
        for res in resArr {
            if res == "" { break }
            validResponses.append(SMTPResponse(code: try getResponseCode(res, command: command), message: getResponseMessage(res), response: res))
        }
        return validResponses
    }
    
    func getResponseCode(_ response: String, command: SMTPCommand) throws -> SMTPResponseCode {
        let range = response.startIndex..<response.index(response.startIndex, offsetBy: 3)
        guard let responseCode = Int(response[range]), command.expectedCodes.contains(SMTPResponseCode(responseCode)) else {
            throw NSError("Command \"\(command.text)\" failed with response: \(response).")
        }
        return SMTPResponseCode(responseCode)
    }
    
    func getResponseMessage(_ response: String) -> String {
        let range = response.index(response.startIndex, offsetBy: 4)..<response.endIndex
        return response[range]
    }
}
