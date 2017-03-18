import Foundation

public class SMTP {
    let config: SMTPConfig
    
    public init(hostname: String, user: String, password: String, accessToken: String? = nil, domainName: String = "localhost", authMethods: [AuthMethod] = AuthMethod.defaultAuthMethods, chainFilePath: String? = nil, chainFilePassword: String? = nil, selfSignedCerts: Bool? = nil) {
        config = SMTPConfig(hostname: hostname, user: user, password: password, accessToken: accessToken, domainName: domainName, authMethods: authMethods, chainFilePath: chainFilePath, chainFilePassword: chainFilePassword, selfSignedCerts: selfSignedCerts)
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
        do {
            try SMTPSender(config).send(mails, progress: progress, completion: completion)
        } catch {
            completion?([], mails.map { ($0, error) })
        }
    }
}

struct SMTPConfig {
    let hostname: String
    let user: String
    let password: String
    let accessToken: String?
    let domainName: String
    let authMethods: [AuthMethod]
    let chainFilePath: String?
    let chainFilePassword: String?
    let selfSignedCerts: Bool?
    
    init(hostname: String, user: String, password: String, accessToken: String?, domainName: String, authMethods: [AuthMethod], chainFilePath: String?, chainFilePassword: String?, selfSignedCerts: Bool?) {
        self.hostname = hostname
        self.user = user
        self.password = password
        self.accessToken = accessToken
        self.domainName = domainName
        
        if authMethods.count > 0 { self.authMethods = authMethods }
        else { self.authMethods = AuthMethod.defaultAuthMethods }
        
        self.chainFilePath = chainFilePath
        self.chainFilePassword = chainFilePassword
        self.selfSignedCerts = selfSignedCerts
    }
}

let CRLF = "\r\n"
