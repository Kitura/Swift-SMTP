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

/// Error type for KituraSMTP.
public enum SMTPError: Error, CustomStringConvertible {
    // AuthCredentials
    /// Hashing server challenge with MD5 algorithm failed.
    case md5HashChallengeFail
    
    /// Error decoding string.
    case base64DecodeFail(String)
    
    // DataSender
    /// File not found at path while trying to send file `Attachment`.
    case fileNotFound(String)
    
    // Login
    /// Could not connect to server within specified timeout. Ensure your
    /// server can connect through `Port` 587 or specify which `Port` to connect
    /// on. Some SMTP servers may require a longer timeout.
    case couldNotConnectToServer(String, Int)
    
    /// The preferred `AuthMethod`s could not be found. Connecting with `SSL`
    /// may be required.
    case noSupportedAuthMethods(String)
    
    /// Attempted to login using `XOAUTH2` but `SMTP` instance was initialized 
    /// without an access token.
    case noAccessToken
    
    // Sender
    /// Failed to create RegularExpression that can check if an email is valid.
    case createEmailRegexFailed
    
    // SMTP
    /// An unknown errored occured while sending an email.
    case unknownError

    /// Swift 3.1 on Linux contains a bug in base64 encoding which causes errors 
    /// in Kitura-SMTP. Please use 3.0.2 or >=3.1.1.
    case swift_3_1_on_linux_not_supported
    
    // SMTPSocket
    /// Error converting Data read from socket to a String.
    case convertDataUTF8Fail(Data)
    
    /// Bad response received for command.
    case badResponse(String, String)
    
    // User
    /// Invalid email provided for `User`.
    case invalidEmail(String)
    
    /// Description of the `SMTPError`.
    public var description: String {
        switch self {
        case .md5HashChallengeFail: return "Hashing server challenge with MD5 algorithm failed."
        case .base64DecodeFail(let s): return "Error decoding string: \(s)."
        case .fileNotFound(let p): return "File not found at path while trying to send file `Attachment`: \(p)."
        case .couldNotConnectToServer(let s, let t): return "Could not connect to server (\(s)) within specified timeout (\(t) seconds). Ensure your server can connect through port 587 or specify which port to connect on. Some SMTP servers may require a longer timeout."
        case .noSupportedAuthMethods(let hostname): return "The preferred authorization methods could not be found on \(hostname). Connecting with SSL may be required."
        case .noAccessToken: return "Attempted to login using XOAUTH2 but SMTP instance was initialized without an access token."
        case .createEmailRegexFailed: return "Failed to create RegularExpression that can check if an email is valid."
        case .unknownError: return "An unknown errored occured while sending an email."
        case .swift_3_1_on_linux_not_supported: return "Swift 3.1 on Linux contains a bug in base64 encoding which causes errors in Kitura-SMTP. Please use 3.0.2 or >=3.1.1."
        case .convertDataUTF8Fail(let buf): return "Error converting Data read from socket to a String: \(buf)."
        case .badResponse(let command, let response): return "Bad response received for command. command: (\(command)), response: \(response)"
        case .invalidEmail(let email): return "Invalid email provided for User: \(email)."
        }
    }
    
    init(_ error: SMTPError, file: String = #file, line: Int = #line) {
        self = error
        Log.debug("[Kitura-SMTP Error]: \(self.description) file: \(file) line: \(line).")
    }
}
