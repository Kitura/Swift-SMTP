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

/// Used to connect to an SMTP server and send emails.
public struct SMTP {
    private let hostname: String
    private let email: String
    private let password: String
    private let port: Int32
    private let tlsMode: TLSMode
    private let tlsConfiguration: TLSConfiguration?
    private let authMethods: [String: AuthMethod]
    private let domainName: String
    private let timeout: UInt

    /// TLSMode enum for what form of connection security to enforce.
    public enum TLSMode {
        /// Upgrades the connection to TLS if STARTLS command is received, else sends mail without security.
        case normal

        /// Send mail over plaintext and ignore STARTTLS commands and TLS options. Could throw an error if server requires TLS.
        case ignoreTLS

        /// Only send mail after an initial successful TLS connection. Connection will fail if a TLS connection cannot be established. The default port, 587, will likely need to be adjusted depending on your server.
        case requireTLS

        /// Expect a STARTTLS command from the server and require the connection is upgraded to TLS. Will throw if the server does not issue a STARTTLS command.
        case requireSTARTTLS
    }

    /// Initializes an `SMTP` instance.
    ///
    /// - Parameters:
    ///     - hostname: Hostname of the SMTP server to connect to, i.e. `smtp.example.com`.
    ///     - email: Username to log in to server.
    ///     - password: Password to log in to server, or access token if using XOAUTH2 authorization method.
    ///     - port: Port to connect to the server on. Defaults to `465`.
    ///     - tlsMode: TLSMode `enum` indicating what form of connection security to use.
    ///     - tlsConfiguration: `TLSConfiguration` used to connect with TLS. If nil, a configuration with no backing
    ///       certificates is used. See `TLSConfiguration` for other configuration options.
    ///     - authMethods: `AuthMethod`s to use to log in to the server. If blank, tries all supported methods.
    ///     - domainName: Client domain name used when communicating with the server. Defaults to `localhost`.
    ///     - timeout: How long to try connecting to the server to before returning an error. Defaults to `10` seconds.
    ///
    /// - Note:
    ///     - You may need to enable access for less secure apps for your account on the SMTP server.
    ///     - Some servers like Gmail support IPv6, and if your network does  not, you will first attempt to connect via
    ///       IPv6, then timeout, and fall back to IPv4. You can avoid this by disabling IPv6 on your machine.
    public init(hostname: String,
                email: String,
                password: String,
                port: Int32 = 587,
                tlsMode: TLSMode = .requireSTARTTLS,
                tlsConfiguration: TLSConfiguration? = nil,
                authMethods: [AuthMethod] = [],
                domainName: String = "localhost",
                timeout: UInt = 10) {
        self.hostname = hostname
        self.email = email
        self.password = password
        self.port = port
        self.tlsMode = tlsMode
        self.tlsConfiguration = tlsConfiguration

        let _authMethods = !authMethods.isEmpty ? authMethods : [
            AuthMethod.cramMD5,
            AuthMethod.login,
            AuthMethod.plain,
            AuthMethod.xoauth2
        ]
        var authMethodsDictionary = [String: AuthMethod]()
        _authMethods.forEach { authMethod in
            authMethodsDictionary[authMethod.rawValue] = authMethod
        }
        self.authMethods = authMethodsDictionary

        self.domainName = domainName
        self.timeout = timeout
    }

    /// Send an email.
    ///
    /// - Parameters:
    ///     - mail: `Mail` object to send.
    ///     - completion: Callback when sending finishes. `Error` is nil on success. (optional)
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
    ///     - progress: (`Mail`, `Error`) callback after each `Mail` is sent. `Mail` is the mail sent and `Error` is
    ///       the error if it failed. (optional)
    ///     - completion: ([`Mail`], [(`Mail`, `Error`)]) callback after all `Mail`s have been attempted. [`Mail`] is an
    ///       array of successfully sent `Mail`s. [(`Mail`, `Error`)] is an array of failed `Mail`s and their
    ///       corresponding `Error`s. (optional)
    ///
    /// - Note:
    ///     - Each call to `send` will first log in to your server, attempt to send the mails, then closes the
    ///       connection. Pass in an array of `Mail`s to send them all in one session.
    ///     - If any of the email addresses in a `Mail`'s `to`, `cc`, or `bcc` are invalid, the entire mail will not
    ///       send and return an `SMTPError`.
    ///     - If an individual `Mail` fails while sending an array of `Mail`s, the whole sending process will continue
    ///       until all pending `Mail`s are attempted.
    ///     - Each call to `send` queues it's `Mail`s and sends them one by one. To send `Mail`s concurrently, send them
    ///       in separate calls to `send`.
    public func send(_ mails: [Mail],
                     progress: Progress = nil,
                     completion: Completion = nil) {
        if mails.isEmpty {
            completion?([], [])
            return
        }
        do {
            let socket = try SMTPSocket(
                hostname: hostname,
                email: email,
                password: password,
                port: port,
                tlsMode: tlsMode,
                tlsConfiguration: tlsConfiguration,
                authMethods: authMethods,
                domainName: domainName,
                timeout: timeout
            )
            MailSender(
                socket: socket,
                mailsToSend: mails,
                progress: progress,
                completion: completion).send()
        } catch {
            completion?([], mails.map { ($0, error) })
        }
    }
}
