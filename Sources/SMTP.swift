import Foundation

/// Represents a handle to connect to and send emails through an SMTP server.
public class SMTP {
    public var config: SMTPConfig
    
    /**
     Initializes an `SMTP` instance.
     
    - parameters:
        - hostname: Hostname of the SMTP server to connect to. Should not
                    include any scheme--ie `smtp.example.com` is valid.
        - user: Username to log in to server.
        - password: Password to log in to server.
        - accessToken: Access token used if logging in through XOAUTH2.
        - domainName: Client domain name used when communicating with the
                      server. Defaults to "localhost".
        - authMethods: Authentication methods to use to log in to the server.
                       Defaults to all supported ones--currently CRAM-MD5,
                       LOGIN, PLAIN, XOAUTH2.
        - chainFilePath: Absolute path to certificate chain .pfx file in PKC12 
                         format. Required if the SMTP server supports SSL.
        - chainFilePassword: Password for certificate chain file.
        - selfSignedCerts: `Bool` indicating if certificates are self signed.
     */
    public init(hostname: String, user: String, password: String, accessToken: String? = nil, domainName: String = "localhost", authMethods: [AuthMethod] = AuthMethod.defaultAuthMethods, chainFilePath: String? = nil, chainFilePassword: String? = nil, selfSignedCerts: Bool? = nil) {
        config = SMTPConfig(hostname: hostname, user: user, password: password, accessToken: accessToken, domainName: domainName, authMethods: authMethods, chainFilePath: chainFilePath, chainFilePassword: chainFilePassword, selfSignedCerts: selfSignedCerts)
    }
    
    /**
     Send an email.
     
     - parameters:
        - mail: `Mail` object to send.
        - completion: Callback when sending finishes. `Error` is nil on success.
     */
    public func send(_ mail: Mail, completion: ((Error?) -> Void)? = nil) {
        send([mail]) { (_, failed) in
            if let err = failed.first?.1 {
                completion?(err)
            } else {
                completion?(nil)
            }
        }
    }
    
    /**
     Send multiple emails.
     
     - parameters:
        - mails: Array of `Mail`s to send.
        - progress: (`Mail`, `Error`) callback after each `Mail` is sent. `Mail`
                    is the `Mail` sent and `Error` is the error if it failed.
        - completion: ([`Mail`], [(`Mail`, `Error`)]) callback after all `Mail`s
                      have been attempted. [`Mail`] is an array of successfully 
                      sent `Mail`s. [(`Mail`, `Error`)] is an array of failed 
                      `Mail`s and their corresponding `Error`s.
     
     - note:
        - If a failure is encountered while sending multiple mails, the whole
          sending process does not stop until all pending mails are attempted.
     
        - Each call to `send` queues it's `mails` and sends them one by one. To
          send mails concurrently, send them in separate calls to `send`.
     */
    public func send(_ mails: [Mail], progress: Progress = nil, completion: Completion = nil) {
        do {
            try SMTPSender(config: config, pending: mails, progress: progress, completion: completion).resume()
        } catch {
            completion?([], mails.map { ($0, error) })
        }
    }
}

/// Supported authentication methods for logging into the SMTP server.
public enum AuthMethod: String {
    case cramMD5 = "CRAM-MD5"
    case login = "LOGIN"
    case plain = "PLAIN"
    case xoauth2 = "XOAUTH2"
    
    static let defaultAuthMethods: [AuthMethod] = [.cramMD5, .login, .plain, .xoauth2]
}

/// Configuration of an `SMTP` instance used to connect to its SMTP server.
public struct SMTPConfig {
    public var hostname: String
    public var user: String
    public var password: String
    public var accessToken: String?
    public var domainName: String
    public var authMethods: [AuthMethod]
    public var chainFilePath: String?
    public var chainFilePassword: String?
    public var selfSignedCerts: Bool?
    
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
