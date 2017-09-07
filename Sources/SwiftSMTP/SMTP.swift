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

/// Port to connect to SMTP server with.
public typealias Port = Int32

/// Common `Port`s.
public enum Ports: Port {
    /// Default `Port`.
    case tls = 587
    /// `Port` used to connect securely.
    case ssl = 465
}

/// Supported authentication methods for logging into the SMTP server.
public enum AuthMethod: String {
    /// CRAM-MD5 authentication.
    case cramMD5 = "CRAM-MD5"
    /// LOGIN authentication.
    case login = "LOGIN"
    /// PLAIN authentication.
    case plain = "PLAIN"
    /// XOAUTH2 authentication. Requires a valid access token.
    case xoauth2 = "XOAUTH2"
}

/// Represents a handle to connect to and send emails to an SMTP server.
public struct SMTP {
    private let hostname: String
    private let email: String
    private let password: String
    private let port: Port
    private let ssl: SSL?
    private let authMethods: [AuthMethod]
    private let domainName: String
    private let accessToken: String?
    private let timeout: UInt

    /// Initializes an `SMTP` instance.
    ///
    /// - Parameters:
    ///     - hostname: Hostname of the SMTP server to connect to. Should not
    ///                 include any scheme--ie `smtp.example.com` is valid.
    ///     - user: Username to log in to server.
    ///     - password: Password to log in to server.
    ///     - port: `Port` to connect to the server on. Defaults to `587`.
    ///     - ssl: `SSL` containing configuration info for connecting securely
    ///            through SSL/TLS. If your server has the option to use SSL,
    ///            Swift-SMTP will automatically attempt to upgrade the 
    ///            connection. If you don't provide an SSL configuration, 
    ///            Swift-SMTP defaults to an SSL configuration with no backing 
    ///            certificates. See `SSL` for other configuration options.
    ///     - authMethods: `AuthMethod`s to use to log in to the
    ///                    server. Defaults to `CRAM-MD5`, `LOGIN`, and `PLAIN`.
    ///     - domainName: Client domain name used when communicating with the
    ///                   server. Defaults to `localhost`.
    ///     - accessToken: Access token used if logging in through `XOAUTH2`.
    ///                    (optional)
    ///     - timeout: How long to try connecting to the server to before
    ///                returning an error. Defaults to `10` seconds.
    ///
    /// - Note:
    ///     - Some servers like Gmail support IPv6, and if your network does 
    ///       not, you will first attempt to connect via IPv6, then timeout, and 
    ///       fall back to IPv4. You can avoid this by disabling IPv6 on your 
    ///       machine.
    ///
    ///     - You may need to enable access for less secure apps in your account
    ///       on the SMTP server.
    public init(hostname: String,
                email: String,
                password: String,
                port: Port = Ports.tls.rawValue,
                ssl: SSL? = nil,
                authMethods: [AuthMethod] = [],
                domainName: String = "localhost",
                accessToken: String? = nil,
                timeout: UInt = 10) {
        self.hostname = hostname
        self.email = email
        self.password = password
        self.port = port
        self.ssl = ssl

        if !authMethods.isEmpty {
            self.authMethods = authMethods
        } else {
            self.authMethods = [AuthMethod.cramMD5,
                                AuthMethod.login,
                                AuthMethod.plain]
        }

        self.domainName = domainName
        self.accessToken = accessToken
        self.timeout = timeout
    }

    /// Send an email.
    ///
    /// - Parameters:
    ///     - mail: `Mail` object to send.
    ///     - completion: Callback when sending finishes. `Error` is nil on
    ///                   success. (optional)
    public func send(_ mail: Mail, completion: ((Error?) -> Void)? = nil) {
        send([mail]) { (_, failed) in
            if let error = failed.first?.1 {
                completion?(error)
            } else {
                completion?(nil)
            }
        }
    }

    /// Send multiple emails.
    ///
    /// - Parameters:
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
    /// - Note:
    ///     - If any of the emails addresses in a `Mail`'s `to`, `cc`, or `bcc`
    ///       are invalid, the entire mail will not send and return an
    ///       `SMTPError`.
    ///
    ///     - If an individual `Mail` fails while sending an array of `Mail`s,
    ///       the whole sending process will not stop until all pending `Mail`s
    ///       are attempted.
    ///
    ///     - Each call to `send` queues it's `Mail`s and sends them one by one.
    ///       To send `Mail`s concurrently, send them in separate calls to
    ///       `send`.
    public func send(_ mails: [Mail],
                     progress: Progress = nil,
                     completion: Completion = nil) {
        if mails.isEmpty {
            completion?([], [])
            return
        }
        do {
            try Login(hostname: hostname,
                      email: email,
                      password: password,
                      port: port,
                      ssl: ssl,
                      authMethods: authMethods,
                      domainName: domainName,
                      accessToken: accessToken,
                      timeout: timeout) { (loginResult) in
                        switch loginResult {
                        case .failure(let error):
                            completion?([], mails.map { ($0, error) })
                        case .success(let socket):
                            Sender(socket: socket,
                                   pending: mails,
                                   progress: progress,
                                   completion: completion).send()
                        }
                }.login()
        } catch {
            completion?([], mails.map { ($0, error) })
        }
    }
}
