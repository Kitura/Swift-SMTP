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
import LoggerAPI

/// Error type for SwiftSMTP.
public enum SMTPError: Error, CustomStringConvertible {
    // AuthCredentials
    /// Error decoding string.
    case base64DecodeFail(string: String)

    /// Hashing server challenge with MD5 algorithm failed.
    case md5HashChallengeFail
    
    // DataSender
    /// File not found at path while trying to send file `Attachment`.
    case fileNotFound(path: String)

    /// The preferred `AuthMethod`s could not be found, or your server is sending back a STARTTLS command and requires a connection upgrade.
    case noAuthMethodsOrRequiresTLS(hostname: String)
    
    // Sender
    /// Mail has no recipients.
    case noRecipients

    /// Failed to create RegularExpression that can check if an email is valid.
    case createEmailRegexFailed

    // SMTPSocket
    /// Bad response received for command.
    case badResponse(command: String, response: String)

    /// Error converting Data read from socket to a String.
    case convertDataUTF8Fail(data: Data)
    
    // User
    /// Invalid email provided for `User`.
    case invalidEmail(email: String)

    /// STARTTLS was required but the server did not request it.
    case requiredSTARTTLS
    
    /// Description of the `SMTPError`.
    public var description: String {
        switch self {
        case .base64DecodeFail(let s): return "Error decoding string: \(s)."
        case .md5HashChallengeFail: return "Hashing server challenge with MD5 algorithm failed."
        case .fileNotFound(let p): return "File not found at path while trying to send file `Attachment`: \(p)."
        case .noAuthMethodsOrRequiresTLS(let hostname): return "The preferred authorization methods could not be found on \(hostname), or your server is sending back a STARTTLS command and requires a connection upgrade."
        case .noRecipients: return "An email requires at least one recipient."
        case .createEmailRegexFailed: return "Failed to create RegularExpression that can check if an email is valid."
        case .badResponse(let command, let response): return "Bad response received for command. command: (\(command)), response: \(response)"
        case .convertDataUTF8Fail(let buf): return "Error converting Data read from socket to a String: \(buf)."
        case .invalidEmail(let email): return "Invalid email provided for User: \(email)."
        case .requiredSTARTTLS: return "STARTTLS was required but the server did not issue a STARTTLS command."
        }
    }

    init(_ error: SMTPError) {
        self = error
        Log.error(description)
    }
}
