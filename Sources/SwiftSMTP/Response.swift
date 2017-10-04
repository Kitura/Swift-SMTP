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

struct Response {
    let code: ResponseCode
    let message: String
    let response: String

    init(code: ResponseCode, message: String, response: String) {
        self.code = code
        self.message = message
        self.response = response
    }
}

struct ResponseCode: Equatable {
    let rawValue: Int
    init(_ value: Int) { rawValue = value }

    static let serviceReady = ResponseCode(220)
    static let connectionClosing = ResponseCode(221)
    static let authSucceeded = ResponseCode(235)
    static let commandOK = ResponseCode(250)
    static let willForward = ResponseCode(251)
    static let containingChallenge = ResponseCode(334)
    static let startMailInput = ResponseCode(354)

    public static func==(lhs: ResponseCode, rhs: ResponseCode) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}
