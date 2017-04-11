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

/// Represents a sender or receiver of an email.
public struct User {
    fileprivate let name: String?
    let email: String
    
    ///  Initializes a `User`.
    ///
    /// - Parameters:
    ///     - name: Display name for the user. Defaults to nil.
    ///     - email: Email address for the user.
    public init(name: String? = nil , email: String) {
        self.name = name
        self.email = email
    }
}

extension User {
    var mime: String {
        if let name = name, let nameEncoded = name.mimeEncoded {
            return "\(nameEncoded) <\(email)>"
        } else {
            return email
        }
    }
}
