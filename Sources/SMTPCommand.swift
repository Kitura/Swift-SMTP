//
//  SMTPCommand.swift
//  KituraSMTP
//
//  Created by Quan Vo on 3/9/17.
//
//

import Foundation

enum SMTPCommand {
    case connect
    case helo(String)
    case ehlo(String)
    case starttls
    case auth(SMTP.AuthMethod, String)
    case authResponse(SMTP.AuthMethod, String)
    case authUser(String)
    case help(String?)
    case rset
    case noop
    case mail(String)
    case rcpt(String)
    case data
    case dataEnd
    case vrfy(String)
    case expn(String)
    case quit
    
    var text: String {
        switch self {
        case .connect: return ""
        case .helo(let domain): return "HELO \(domain)"
        case .ehlo(let domain): return "EHLO \(domain)"
        case .starttls: return "STARTTLS"
        case .auth(let method, let credentials): return "AUTH \(method.rawValue) \(credentials)"
        case .authUser(let user): return user
        case .authResponse(let method, let credentials):
            switch method {
            case .cramMD5: return credentials
            case .login: return credentials
            default: fatalError("Can not response to a challenge.")
            }
        case .help(let args): return args != nil ? "HELP \(args!)" : "HELP"
        case .rset: return "RSET"
        case .noop: return "NOOP"
        case .mail(let from): return "MAIL FROM: <\(from)>"
        case .rcpt(let to): return "RCPT TO: <\(to)>"
        case .data: return "DATA"
        case .dataEnd: return "\(CRLF)."
        case .vrfy(let address): return "VRFY \(address)"
        case .expn(let address): return "EXPN \(address)"
        case .quit: return "QUIT"
        }
    }
    
    static let validAuthCodes: [SMTPResponseCode] = [.authSucceeded, .authNotAdvertised, .authFailed]
    
    var expectedCodes: [SMTPResponseCode] {
        switch self {
        case .connect: return [.serviceReady]
        case .starttls: return [.serviceReady]
        case .auth(let method, _):
            switch method {
            case .cramMD5: return [.containingChallenge]
            case .login: return [.containingChallenge]
            case .plain: return SMTPCommand.validAuthCodes
            case .xOauth2: return SMTPCommand.validAuthCodes
            }
        case .authUser(_): return [.containingChallenge]
        case .authResponse(let method, _):
            switch method {
            case .cramMD5: return SMTPCommand.validAuthCodes
            case .login:   return SMTPCommand.validAuthCodes
            default: fatalError("Can not response to a challenge.")
            }
        case .help(_): return [.systemStatus, .helpMessage]
        case .rcpt(_): return [.commandOK, .willForward]
        case .data: return [.startMailInput]
        case .vrfy(_): return [.commandOK, .willForward, .forAttempt]
        case .quit: return [.connectionClosing, .commandOK]
        default: return [.commandOK]
        }
    }
}
