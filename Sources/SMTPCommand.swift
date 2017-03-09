//
//  SMTPCommand.swift
//  KituraSMTP
//
//  Created by Quan Vo on 3/9/17.
//
//

import Foundation

enum SMTPCommand {
    /// helo(domain: String)
    case helo(String)
    /// ehlo(domain: String)
    case ehlo(String)
    case starttls
    /// help(args: String)
    case help(String?)
    case rset
    case noop
    /// mail(from: String)
    case mail(String)
    /// rcpt(to: String)
    case rcpt(String)
    case data
    case dataEnd
    /// verify(address: String)
    case vrfy(String)
    /// expn(String)
    case expn(String)
    /// auth(method: String, body: String)
//    case auth(SMTP.AuthMethod, String)
//    case authResponse(SMTP.AuthMethod, String)
    case authUser(String)
    case quit
}

extension SMTPCommand {
    static let validAuthCodes: [SMTPResponseCode] =
        [.authSucceeded, .authNotAdvertised, .authFailed]
    
    var text: String {
        switch self {
        case .helo(let domain):
            return "HELO \(domain)"
        case .ehlo(let domain):
            return "EHLO \(domain)"
        case .starttls:
            return "STARTTLS"
        case .help(let args):
            return args != nil ? "HELP \(args!)" : "HELP"
        case .rset:
            return "RSET"
        case .noop:
            return "NOOP"
        case .mail(let from):
            return "MAIL FROM: <\(from)>"
        case .rcpt(let to):
            return "RCPT TO: <\(to)>"
        case .data:
            return "DATA"
        case .dataEnd:
            return "\(CRLF)."
        case .vrfy(let address):
            return "VRFY \(address)"
        case .expn(let address):
            return "EXPN \(address)"
//        case .auth(let method, let body):
//            return "AUTH \(method.rawValue) \(body)"
        case .authUser(let body):
            return body
//        case .authResponse(let method, let body):
//            switch method {
//            case .cramMD5: return body
//            case .login: return body
//            default: fatalError("Can not response to a challenge.")
//            }
        case .quit:
            return "QUIT"
        }
    }
    
    var expectedCodes: [SMTPResponseCode] {
        switch self {
        case .starttls:
            return [.serviceReady]
//        case .auth(let method, _):
//            switch method {
//            case .cramMD5: return [.containingChallenge]
//            case .login:   return [.containingChallenge]
//            case .plain:   return SMTPCommand.validAuthCodes
//            case .xOauth2: return SMTPCommand.validAuthCodes
//            }
        case .authUser(_):
            return [.containingChallenge]
//        case .authResponse(let method, _):
//            switch method {
//            case .cramMD5: return SMTPCommand.validAuthCodes
//            case .login:   return SMTPCommand.validAuthCodes
//            default: fatalError("Can not response to a challenge.")
//            }
        case .help(_):
            return [.systemStatus, .helpMessage]
        case .rcpt(_):
            return [.commandOK, .willForward]
        case .data:
            return [.startMailInput]
        case .vrfy(_):
            return [.commandOK, .willForward, .forAttempt]
        case .quit:
            return [.connectionClosing, .commandOK]
        default:
            return [.commandOK]
        }
    }
}

struct SMTPResponseCode: Equatable {
    
    let rawValue: Int
    init(_ value: Int) { rawValue = value }
    
    static let systemStatus = SMTPResponseCode(211)
    static let helpMessage = SMTPResponseCode(214)
    static let serviceReady = SMTPResponseCode(220)
    static let connectionClosing = SMTPResponseCode(221)
    static let authSucceeded = SMTPResponseCode(235)
    static let commandOK = SMTPResponseCode(250)
    static let willForward = SMTPResponseCode(251)
    static let forAttempt = SMTPResponseCode(252)
    static let containingChallenge = SMTPResponseCode(334)
    static let startMailInput = SMTPResponseCode(354)
    static let authNotAdvertised = SMTPResponseCode(503)
    static let authFailed = SMTPResponseCode(535)
    
    public static func ==(lhs: SMTPResponseCode, rhs: SMTPResponseCode) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}
