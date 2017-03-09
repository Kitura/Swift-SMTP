import Foundation
import Socket

/// Used to connect to an SMTP server and send emails.
public class SMTP {
    public typealias Port = Int32
    
    let hostname: String
    let port: Port
    let authMethod: AuthMethod
    let username: String
    let password: String
    let domainName: String
    fileprivate var socket: Socket
    fileprivate var loggedIn = false
    fileprivate var features: Feature?
    
    public init(url: String, port: Port, username: String, authMethod: AuthMethod = .plain, password: String, domainName: String = "localhost") throws {
        self.hostname = url
        self.port = port
        self.authMethod = authMethod
        self.username = username
        self.password = password
        self.domainName = domainName
        socket = try Socket.create()
    }
    
    deinit {
        socket.close()
    }
}

// MARK: - Connect to SMTP server
fileprivate extension SMTP {
    // TODO: - Add checks for if SMTP is already trying to connect
    func setup() throws {
        if !isConnected() {
            try connect()
            if !loggedIn {
                try login()
            }
        }
    }
    
    func connect() throws {
        try socket.connect(to: hostname, port: port)
        _ = try parseResponses(try readFromSocket(), command: .connect)
    }
    
    func isConnected() -> Bool {
        return socket.isConnected
    }
}

// MARK: - Login to SMTP server
fileprivate extension SMTP {
    func login() throws {
        try getFeatures()
        // TODO: - Do auth stuff depending on result of EHLO/HELO
        switch authMethod {
        case .plain:
            _ = try auth(authMethod: .plain, credentials: CryptoEncoder.plain(user: username, password: password))
        default:
            break
        }
        loggedIn = true
    }
    
    func getFeatures() throws {
        var res = [SMTPResponse]()
        do { res = try ehlo() }
        catch { res = try helo() }
        updateFeatures(res)
    }
    
    struct Feature {
        let data: [String: Any]
        init(_ data: [String: Any]) {
            self.data = data
        }
    }
    
    func updateFeatures(_ res: [SMTPResponse]) {
        
    }
}

// MARK: - Authentication method for SMTP server
extension SMTP {
    public enum AuthMethod: String {
        case plain = "PLAIN"
        case login = "LOGIN"
        case cramMD5 = "CRAM-MD5"
        case xOauth2 = "XOAUTH2"
    }
}

// MARK: - Send email
extension SMTP {
    public func send(_ mail: Mail) throws {
        try setup()
        _ = try sendMail(mail.from.email)
        _ = try sendTo(mail.to[0].email)
        try sendData(mail)
    }
    
    private func sendData(_ mail: Mail) throws {
        _ = try data()
        try write("From: \"\(mail.from.name)\" <\(mail.from.email)>")
        try write("To: \"\(mail.to[0].name)\" <\(mail.to[0].email)>")
        try write("Subject: \(mail.subject)")
        try write("")
        try write("\(mail.text)")
        _ = try dataEnd()
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
    
    func starttls() throws -> SMTPResponse {
        return try send(.starttls)
    }
    
    func auth(authMethod: AuthMethod, credentials: String) throws -> SMTPResponse {
        return try send(.auth(authMethod, credentials))
    }
    
    func help(_ args: String? = nil) throws -> SMTPResponse {
        return try send(.help(args))
    }
    
    func rset() throws -> SMTPResponse {
        return try send(.rset)
    }
    
    func noop() throws -> SMTPResponse {
        return try send(.noop)
    }
    
    func sendMail(_ from: String) throws -> SMTPResponse {
        return try send(.mail(from))
    }
    
    func sendTo(_ to: String) throws -> SMTPResponse {
        return try send(.rcpt(to))
    }
    
    func data() throws -> SMTPResponse {
        return try send(.data)
    }
    
    func dataEnd() throws -> SMTPResponse {
        return try send(.dataEnd)
    }
    
    func vrfy(address: String) throws -> SMTPResponse {
        return try send(.vrfy(address))
    }
    
    func expn(address: String) throws -> SMTPResponse {
        return try send(.expn(address))
    }
    
    func quit() throws -> SMTPResponse {
        defer { socket.close() }
        return try send(.quit)
    }
}

// MARK: - Supporting functions to send commands
fileprivate extension SMTP {
    func send(_ command: SMTPCommand) throws -> SMTPResponse {
        try write(command.text)
        return try parseResponses(try readFromSocket(), command: command)[0]
    }
    
    func send(_ command: SMTPCommand) throws -> [SMTPResponse] {
        try write(command.text)
        return try parseResponses(try readFromSocket(), command: command)
    }
    
    func write(_ commandText: String) throws {
        _ = try socket.write(from: commandText + CRLF)
    }
    
    func readFromSocket() throws -> String {
        var buf = Data()
        _ = try socket.read(into: &buf)
        guard let res = String(data: buf, encoding: .utf8) else {
            throw NSError("Error converting data to string.")
        }
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
            throw NSError("Unexpected response for command \"\(command.text)\": \(response).")
        }
        return SMTPResponseCode(responseCode)
    }
    
    func getResponseMessage(_ response: String) -> String {
        let range = response.index(response.startIndex, offsetBy: 4)..<response.endIndex
        return response[range]
    }
}
