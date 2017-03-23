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

struct SMTPResponse {
    let code: SMTPResponseCode
    let message: String
    let response: String
    
    init(code: SMTPResponseCode, message: String, response: String) {
        self.code = code
        self.message = message
        self.response = response
    }
}

struct SMTPResponseCode: Equatable {
    let rawValue: Int
    init(_ value: Int) { rawValue = value }
    
    static let serviceReady = SMTPResponseCode(220)
    static let connectionClosing = SMTPResponseCode(221)
    static let authSucceeded = SMTPResponseCode(235)
    static let commandOK = SMTPResponseCode(250)
    static let willForward = SMTPResponseCode(251)
    static let containingChallenge = SMTPResponseCode(334)
    static let startMailInput = SMTPResponseCode(354)
    
    public static func ==(lhs: SMTPResponseCode, rhs: SMTPResponseCode) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}
