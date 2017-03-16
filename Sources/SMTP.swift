import Foundation

public class SMTP {
    let hostname: String
    let user: String
    let password: String
    let accessToken: String?
    let domainName: String
    let authMethods: [AuthMethod]
    let chainFilePath: String?
    let chainFilePassword: String?
    let selfSignedCerts: Bool?
    fileprivate let send: SMTPSend
    
    public enum AuthMethod: String {
        case cramMD5 = "CRAM-MD5"
        case login = "LOGIN"
        case plain = "PLAIN"
        case xoauth2 = "XOAUTH2"
    }
    
    private static let defaultAuthMethods: [AuthMethod] = [.cramMD5, .login, .plain, .xoauth2]
    
    public init(hostname: String, user: String, password: String, accessToken: String? = nil, domainName: String = "localhost", authMethods: [AuthMethod] = SMTP.defaultAuthMethods, chainFilePath: String? = nil, chainFilePassword: String? = nil, selfSignedCerts: Bool? = nil) throws {
        self.hostname = hostname
        self.user = user
        self.password = password
        self.accessToken = accessToken
        self.domainName = domainName
        
        if authMethods.count > 0 { self.authMethods = authMethods }
        else { self.authMethods = SMTP.defaultAuthMethods }
        
        self.chainFilePath = chainFilePath
        self.chainFilePassword = chainFilePassword
        self.selfSignedCerts = selfSignedCerts
        send = try SMTPSend(hostname: hostname, user: user, password: password, accessToken: accessToken, domainName: domainName, authMethods: authMethods, chainFilePath: chainFilePath, chainFilePassword: chainFilePassword, selfSignedCerts: selfSignedCerts)
    }
    
    public func send(_ mail: Mail, completion: ((Error?) -> Void)? = nil) {
        send([mail]) { (_, failed) in
            if let err = failed.first?.1 {
                completion?(err)
            } else {
                completion?(nil)
            }
        }
    }
    
    public func send(_ mails: [Mail], progress: ((Mail, Error?) -> Void)? = nil, completion: ((_ sent: [Mail], _ failed: [(mail: Mail, error: Error)]) -> Void)? = nil) {
        send.send(mails, progress: progress, completion: completion)
    }
}
