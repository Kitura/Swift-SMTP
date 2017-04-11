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
    /// Creating the HMAC for CRAM-MD5 authentication failed.
    case md5HashChallengeFail
    /// Decoding the base64 encoded String failed.
    case base64DecodeFail(String)
    
    // SMTP
    /// An unknown errored occured while sending an email.
    case unknownError
    
    // SMTPDataSender
    /// File not found at path while trying to send a file `Attachment`.
    case fileNotFound(String)
    
    // SMTPLogin
    /// Connecting to server timed out. Check that you are connecting to a valid
    /// `Port` for your SMTP server.
    case couldNotConnectToServer(String, Int)
    
    /// This SMTP server does not support any authentication methods that
    /// were provided on initialization of this instance of `SMTP`.
    case noSupportedAuthMethods(String)
    
    /// Authenticating with XOAUTH2 requres a valid access token.
    case noAccessToken
    
    // SMTPSocket
    /// Converting Data read from socket to a String failed.
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
        case .unknownError: return "Unknown error occurred while trying to send mail."
        case .fileNotFound(let p): return "File not found at path: \(p)."
        case .couldNotConnectToServer(let s, let t): return "Could not connect to server (\(s)) within specified timeout (\(t) seconds). Ensure your server can connect through port 587 or specify which port to connect on. Some SMTP servers may require a longer timeout."
        case .noSupportedAuthMethods(let hostname): return "The preferred authorization methods could not be found on \(hostname). Connecting with SSL may be required."
        case .noAccessToken: return "Attempted to login using XOAUTH2 but SMTP instance was initialized without an access token."
        case .convertDataUTF8Fail(let buf): return "Error converting data to string: \(buf)."
        case .badResponse(let command, let response): return "Command (\(command)) returned bad response: \(response)."
        case .invalidEmail(let email): return "Invalid email: \(email)."
        }
    }
    
    init(_ error: SMTPError, file: String = #file, line: Int = #line) {
        self = error
        Log.debug("[Kitura-SMTP Error]: \(self.description) file: \(file) line: \(line).")
    }
}
