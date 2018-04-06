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

/// Represents a handle to connect, authenticate, and send emails to an SMTP server.
public struct SMTP {
    private let loginManager: LoginManaging

    /// Initializes an `SMTP` instance.
    ///
    /// - Parameters:
    ///     - hostname: Hostname of the SMTP server to connect to.
    ///                 Should not include any scheme--ie `smtp.example.com` is valid.
    ///     - email: Username to log in to server.
    ///     - password: Password to log in to server.
    ///     - port: Port to connect to the server on. Defaults to `465`.
    ///     - useTLS: `Bool` indicating whether to connect with TLS. Your server must support the `STARTTLS` command.
    ///               Defaults to `true`.
    ///     - tlsConfiguration: `TLSConfiguration` used to connect with TLS. If nil, a configuration with no backing
    ///                         certificates is used. See `TLSConfiguration` for other configuration options.
    ///     - authMethods: `AuthMethod`s to use to log in to the server. Defaults to `CRAM-MD5`, `LOGIN`, and `PLAIN`.
    ///     - accessToken: Access token used IFF logging in through `XOAUTH2`.
    ///     - domainName: Client domain name used when communicating with the server. Defaults to `localhost`.
    ///     - timeout: How long to try connecting to the server to before returning an error. Defaults to `10` seconds.
    ///
    /// - Note:
    ///     - Some servers like Gmail support IPv6, and if your network does  not, you will first attempt to connect via
    ///       IPv6, then timeout, and fall back to IPv4. You can avoid this by disabling IPv6 on your machine.
    ///     - You may need to enable access for less secure apps in your account on the SMTP server.
    public init(hostname: String,
                email: String,
                password: String,
                port: Int32 = 465,
                useTLS: Bool = true,
                tlsConfiguration: TLSConfiguration? = nil,
                authMethods: [AuthMethod] = [],
                accessToken: String? = nil,
                domainName: String = "localhost",
                timeout: UInt = 10) {
        loginManager = LoginManager(
            hostname: hostname,
            email: email,
            password: password,
            port: port,
            useTLS: useTLS,
            tlsConfiguration: tlsConfiguration,
            authMethods: !authMethods.isEmpty ? authMethods : [
                AuthMethod.cramMD5,
                AuthMethod.login,
                AuthMethod.plain
            ],
            accessToken: accessToken,
            domainName: domainName,
            timeout: timeout)
    }

    init(loginManager: LoginManaging) {
        self.loginManager = loginManager
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
    ///     - progress: (`Mail`, `Error`) callback after each `Mail` is sent. `Mail` is the `Mail` sent and `Error` is
    ///                 the error if it failed. (optional)
    ///     - completion: ([`Mail`], [(`Mail`, `Error`)]) callback after all `Mail`s have been attempted. [`Mail`] is an
    ///                   array of successfully sent `Mail`s. [(`Mail`, `Error`)] is an array of failed `Mail`s and
    ///                   their corresponding `Error`s. (optional)
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
        loginManager.login { result in
            switch result {
            case .failure(let error):
                completion?([], mails.map { ($0, error) })
            case .success(let socket):
                MailSender(
                    socket: socket,
                    mailsToSend: mails,
                    progress: progress,
                    completion: completion).send()
            }
        }
    }
}
