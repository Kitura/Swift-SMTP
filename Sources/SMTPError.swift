import Foundation

enum SMTPError: Error {
    // AuthCredentials
    case md5HashChallengeFail
    case base64DecodeFail(String)
    
    // SMTPDataSendr
    case fileNotFound(String)
    
    // SMTPLogin
    case certChainFileInfoMissing(String)
    case noSupportedAuthMethods(String)
    case noAccessToken
    
    // SMTPSender
    case smtpInstanceIsSending
    
    // SMTPSocket
    case convertDataUTF8Fail(Data)
    case badResponse(String, String)
    
    // User
    case invalidEmail(String)
    
    var localizedDescription: String {
        switch self {
        case .md5HashChallengeFail: return "Hashing server challenge with MD5 algorithm failed."
        case .base64DecodeFail(let s): return "Error decoding string: \(s)."
        case .fileNotFound(let p): return "File not found at path: \(p)."
        case .certChainFileInfoMissing(let hostname): return "\(hostname) offers STARTTLS. SMTP instance must be initialized with a valid Certificate Chain File path in PKCS12 format and password."
        case .noSupportedAuthMethods(let hostname): return "No supported authorization methods that matched the preferred authorization methods were found on \(hostname)."
        case .noAccessToken: return "Attempted to login using XOAUTH2 but SMTP instance was initialized without an access token."
        case .smtpInstanceIsSending: return "Attempted to send mail using an SMTP instance that was already in the process of sending mails."
        case .convertDataUTF8Fail(let buf): return "Error converting data to string: \(buf)."
        case .badResponse(let command, let response): return "Command \"\(command)\" failed with response: \(response)."
        case .invalidEmail(let email): return "Invalid email: \(email)"
        }
    }
    
    init(_ error: SMTPError, file: String = #file, line: Int = #line) {
        self = error
        print("[Kitura-SMTP Error]: \(self.localizedDescription) file: \(file) line: \(line).")
    }
}
