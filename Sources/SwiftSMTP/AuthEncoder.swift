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
import Cryptor

struct AuthEncoder {
    static func cramMD5(challenge: String, user: String, password: String) throws -> String {
        guard let hmac = HMAC(
            using: HMAC.Algorithm.md5,
            key: password).update(string: try challenge.base64Decoded())?.final() else {
                throw SMTPError.md5HashChallengeFail
        }
        let digest = CryptoUtils.hexString(from: hmac)
        return ("\(user) \(digest)").base64Encoded
    }

    static func login(user: String, password: String) -> (encodedUser: String, encodedPassword: String) {
        return (user.base64Encoded, password.base64Encoded)
    }

    static func plain(user: String, password: String) -> String {
        let text = "\u{0000}\(user)\u{0000}\(password)"
        return text.base64Encoded
    }

    static func xoauth2(user: String, accessToken: String) -> String {
        let text = "user=\(user)\u{0001}auth=Bearer \(accessToken)\u{0001}\u{0001}"
        return text.base64Encoded
    }
}

extension String {
    func base64Decoded() throws -> String {
        guard let data = Data(base64Encoded: self),
            let base64Decoded = String(data: data, encoding: .utf8) else {
                throw SMTPError.base64DecodeFail(string: self)
        }
        return base64Decoded
    }
}
