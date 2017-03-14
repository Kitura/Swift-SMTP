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
    case auth(SMTP.AuthMethod, String?)
    case authUser(String)
    case authPassword(String)
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
        case .auth(let method, let credentials):
            if let credentials = credentials { return "AUTH \(method.rawValue) \(credentials)" }
            else { return "AUTH \(method.rawValue)" }
        case .authUser(let user): return user
        case .authPassword(let password): return password
        case .help(let args):
            if let args = args { return "HELP \(args)" }
            else { return "HELP" }
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
        
    var expectedCodes: [SMTPResponseCode] {
        switch self {
        case .connect: return [.serviceReady]
        case .starttls: return [.serviceReady]
        case .auth(let method, _):
            switch method {
            case .cramMD5: return [.containingChallenge]
            case .login: return [.containingChallenge]
            case .plain: return [.authSucceeded]
            case .xOauth2: return [.authSucceeded]
            }
        case .authUser(_): return [.containingChallenge]
        case .authPassword: return [.authSucceeded]
        case .help(_): return [.systemStatus, .helpMessage]
        case .rcpt(_): return [.commandOK, .willForward]
        case .data: return [.startMailInput]
        case .vrfy(_): return [.commandOK, .willForward, .forAttempt]
        case .quit: return [.connectionClosing, .commandOK]
        default: return [.commandOK]
        }
    }
}
