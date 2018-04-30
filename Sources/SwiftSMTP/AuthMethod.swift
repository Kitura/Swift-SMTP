/**
 * Copyright IBM Corporation 2018
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
