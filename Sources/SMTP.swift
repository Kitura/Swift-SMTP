import Foundation
import Socket

public typealias Port = Int32

/// Used to connect to an SMTP server and send emails.
class SMTP {
    let hostname: String
    let port: Port
    let username: String
    let password: String
    let domainName: String
    fileprivate var socket: Socket
    fileprivate var loggedIn = false
    fileprivate var features: Feature?
    
    init(url: String, port: Port, username: String, password: String, domainName: String="localhost") throws {
        self.hostname = url
        self.port = port
        self.username = username
        self.password = password
        self.domainName = domainName
        socket = try Socket.create()
    }
    
    fileprivate func read() throws {
        var buf = Data()
        _ = try socket.read(into: &buf)
        print(String(data: buf, encoding: .utf8) as Any)
    }
    
    deinit {
        socket.close()
    }
}

// MARK: - Send email
extension SMTP {
    public func send(_ mail: Mail) throws {
        try setup()
        
        
//        try socket.write(from: "EHLO \(domainName)" + CRLF)
//        try read()
//        
//        try socket.write(from: "AUTH PLAIN \(CryptoEncoder.plain(user: username, password: password))" + CRLF)
//        try read()
//        
//        try socket.write(from: "MAIL FROM: <\(mail.from.email)>" + CRLF)
//        try read()
//        
//        try socket.write(from: "RCPT TO: <\(mail.to[0].email)>" + CRLF)
//        try read()
//        
//        try socket.write(from: "DATA" + CRLF)
//        try read()
//        
//        try socket.write(from: "From: \"\(mail.from.name)\" <\(mail.from.email)>" + CRLF)
//        try socket.write(from: "To: \"\(mail.to[0].name)\" <\(mail.to[0].email)>" + CRLF)
//        try socket.write(from: "Subject: \(mail.subject)" + CRLF)
//        try socket.write(from: CRLF)
//        try socket.write(from: "\(mail.text)" + CRLF)
//        
//        try socket.write(from: "." + CRLF)
//        try read()
    }
}

// MARK: - Connect to SMTP server
fileprivate extension SMTP {
    // TODO: - Add checks for if SMTP is already trying to connect
    func setup() throws {
        if !isConnected() {
            try socket.connect(to: hostname, port: port)
            try read()
            if !loggedIn {
                try login()
            }
        }
    }
    
    func isConnected() -> Bool {
        return socket.isConnected
    }
}

// MARK: - Login
fileprivate extension SMTP {
    func login() throws {
        try getFeatures()
        // TODO: - Do auth stuff depending on result of EHLO/HELO
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

// MARK: - Send a command to the SMTP server
fileprivate extension SMTP {
    func send(_ command: SMTPCommand) throws -> [SMTPResponse] {
        try write(command.text)
        let res = try readFromSocket()
        return try parseResponses(res, command: command)
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
    
    func parseResponses(_ res: String, command: SMTPCommand) throws -> [SMTPResponse] {
        var responses = [SMTPResponse]()
        let resArr = res.components(separatedBy: CRLF)
        for r in resArr {
            if r == "" { break }
            responses.append(SMTPResponse(code: try getResponseCode(r, command: command), message: getResponseMessage(r), response: r))
        }
        return responses
    }
    
    func getResponseCode(_ res: String, command: SMTPCommand) throws -> SMTPResponseCode {
        let range = res.startIndex..<res.index(res.startIndex, offsetBy: 3)
        guard let responseCode = Int(res[range]) else {
            throw NSError("Bad response code for command \"\(command).")
        }
        let smtpResponseCode = SMTPResponseCode(responseCode)
        guard command.expectedCodes.contains(smtpResponseCode) else {
            throw NSError("Unexpected response code for command \"\(command)\": \(smtpResponseCode).")
        }
        return smtpResponseCode
    }
    
    func getResponseMessage(_ res: String) -> String {
        let range = res.index(res.startIndex, offsetBy: 4)..<res.endIndex
        return res[range]
    }
}

// MARK: - SMTP Commands
fileprivate extension SMTP {
    func ehlo() throws -> [SMTPResponse] {
        return try send(.ehlo(domainName))
    }
    
    func helo() throws -> [SMTPResponse] {
        return try send(.helo(domainName))
    }
    
    func sendMail(_ from: String) throws -> [SMTPResponse] {
        return try send(.mail(from))
    }
    
    func sendTo(_ to: String) throws -> [SMTPResponse] {
        return try send(.rcpt(to))
    }
}

// MARK: - Error messages
extension SMTP {
    public enum SMTPError: Error, CustomStringConvertible {
        case couldNotConnect
        case timeOut
        case badResponse
        case noConnection
        case authFailed
        case authNotSupported
        case authUnadvertised
        case connectionClosed
        case connectionEnded
        case connectionAuth
        case unknown
        
        public var description: String {
            switch self {
            case .couldNotConnect: return "Could not connect to SMTP server."
            case .timeOut: return "Connecting to SMTP server time out."
            case .badResponse: return "Bad response."
            case .noConnection: return "No connection has been established."
            case .authFailed: return "Authorization failed."
            case .authUnadvertised: return "Can not authorizate since target server does not support EHLO."
            case .authNotSupported: return "No form of authorization supported."
            case .connectionClosed: return "Connection closed by remote."
            case .connectionEnded: return "Connection ended."
            case .connectionAuth: return "Connection auth failed."
            case .unknown: return "Unknown error."
            }
        }
    }
}
