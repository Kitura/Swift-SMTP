/**
 * Copyright IBM Corporation 2017
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

import Foundation

/// Port to connect to SMTP server with
public typealias Port = Int32

/// Supported authentication methods for logging into the SMTP server.
public enum AuthMethod: String {
    case cramMD5 = "CRAM-MD5"
    case login = "LOGIN"
    case plain = "PLAIN"
    case xoauth2 = "XOAUTH2"
    
    static let defaultAuthMethods: [AuthMethod] = [.cramMD5, .login, .plain, .xoauth2]
}

/// Represents a handle to connect to and send emails through an SMTP server.
public struct SMTP {
    public let hostname: String
    public let user: String
    public let password: String
    public let port: Port
    public let accessToken: String?
    public let domainName: String
    public let authMethods: [AuthMethod]
    public let chainFilePath: String?
    public let chainFilePassword: String?
    public let selfSignedCerts: Bool?
    
    /// Initializes an `SMTP` instance.
    ///
    /// - parameters:
    ///     - hostname: Hostname of the SMTP server to connect to. Should not
    ///                include any scheme--ie `smtp.example.com` is valid.
    ///     - user: Username to log in to server.
    ///     - password: Password to log in to server.
    ///     - port: Port to connect to the server on. If server doesn't 
    ///             recognize the given port, process will hang. If server
    ///             responds with an error, tries the default port. Default is
    ///             587. Uses 465 when upgrading to secure connection.
    ///     - accessToken: Access token used if logging in through XOAUTH2.
    ///     - domainName: Client domain name used when communicating with the
    ///                  server. Defaults to "localhost".
    ///     - authMethods: Authentication methods to use to log in to the 
    ///                    server. Defaults to all supported ones--currently 
    ///                    CRAM-MD5, LOGIN, PLAIN, XOAUTH2.
    ///     - chainFilePath: Absolute path to certificate chain .pfx file in 
    ///                      PKC12 format. Required if the SMTP server supports 
    ///                      SSL.
    ///     - chainFilePassword: Password for certificate chain file.
    ///     - selfSignedCerts: `Bool` indicating if certificates are self 
    ///                        signed.
    public init(hostname: String, user: String, password: String, port: Port = Proto.tls.rawValue, accessToken: String? = nil, domainName: String = "localhost", authMethods: [AuthMethod] = AuthMethod.defaultAuthMethods, chainFilePath: String? = nil, chainFilePassword: String? = nil, selfSignedCerts: Bool? = nil) {
        self.hostname = hostname
        self.user = user
        self.password = password
        self.port = port
        self.accessToken = accessToken
        self.domainName = domainName
        
        if !authMethods.isEmpty { self.authMethods = authMethods }
        else { self.authMethods = AuthMethod.defaultAuthMethods }
        
        self.chainFilePath = chainFilePath
        self.chainFilePassword = chainFilePassword
        self.selfSignedCerts = selfSignedCerts
    }
    
    /// Send an email.
    ///
    /// - parameters:
    ///     - mail: `Mail` object to send.
    ///     - completion: Callback when sending finishes. `Error` is nil on 
    ///                   success.
    public func send(_ mail: Mail, completion: ((Error?) -> Void)? = nil) {
        send([mail]) { (_, failed) in
            if let err = failed.first?.1 {
                completion?(err)
            } else {
                completion?(nil)
            }
        }
    }
    
    /// Send multiple emails.
    ///
    /// - parameters:
    ///     - mails: Array of `Mail`s to send.
    ///     - progress: (`Mail`, `Error`) callback after each `Mail` is sent. 
    ///                 `Mail` is the `Mail` sent and `Error` is the error if it 
    ///                 failed. (optional)
    ///     - completion: ([`Mail`], [(`Mail`, `Error`)]) callback after all 
    ///                   `Mail`s have been attempted. [`Mail`] is an array of 
    ///                   successfully sent `Mail`s. [(`Mail`, `Error`)] is an 
    ///                   array of failed `Mail`s and their corresponding 
    ///                   `Error`s. (optional)
    ///
    /// - note:
    ///     - If a failure is encountered while sending multiple mails, the 
    ///       whole sending process does not stop until all pending mails are
    ///       attempted.
    ///
    ///     - Each call to `send` queues it's `Mail`s and sends them one by one. 
    ///       To send `Mail`s concurrently, send them in separate calls to 
    ///       `send`.
    public func send(_ mails: [Mail], progress: Progress = nil, completion: Completion = nil) {
        do {
            let socket = try SMTPLogin(hostname: hostname, user: user, password: password, port: port, accessToken: accessToken, domainName: domainName, authMethods: authMethods, chainFilePath: chainFilePath, chainFilePassword: chainFilePassword, selfSignedCerts: selfSignedCerts).login()
            try SMTPSender(socket: socket, pending: mails, progress: progress, completion: completion).resume()
        } catch {
            completion?([], mails.map { ($0, error) })
        }
    }
}
