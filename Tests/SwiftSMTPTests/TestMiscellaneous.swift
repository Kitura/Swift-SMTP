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

import XCTest
@testable import SwiftSMTP

#if os(Linux) && !swift(>=3.1)
    import Foundation
#endif

class TestMiscellaneous: XCTestCase {
    static var allTests = [
        ("testDateFormatter", testDateFormatter),
        ("testMailHeaders", testMailHeaders),
        ("testTakeLast1", testTakeLast1),
        ("testTakeLast1", testTakeLast1),
        ("testMimeNoName", testMimeNoName),
        ("testMimeWithName", testMimeWithName),
        ("testBase64Encoded", testBase64Encoded),
        ("testMimeEncoded", testMimeEncoded)
    ]

    let a = ["a"]
    let b = ["b"]
    let ab = ["a", "c"]
}

// Mail
extension TestMiscellaneous {
    func testDateFormatter() {
        let date = Date(timeIntervalSince1970: 0)
        let formatter = DateFormatter.smtpDateFormatter
        formatter.timeZone = TimeZone(secondsFromGMT: 3600 * 9)
        let result = formatter.string(from: date)
        let expected = "Thu, 1 Jan 1970 09:00:00 +0900"
        XCTAssertEqual(result, expected, "result: \(result) != expected: \(expected)")
    }

    func testMailHeaders() {
        let headers = Mail(from: from, to: [to], cc: [to2], subject: "Test", text: text, additionalHeaders: ["key": "val"]).headers

        let to_ = "TO: =?UTF-8?Q?Megaman?= <kiturasmtp@gmail.com>"
        XCTAssert(headers.contains(to_), "Mail header did not contain \(to_)")

        let cc_ = "CC: =?UTF-8?Q?Roll?= <kiturasmtp2@gmail.com>"
        XCTAssert(headers.contains(cc_), "Mail header did not contain \(cc_)")

        let subject = "SUBJECT: =?UTF-8?Q?Test?="
        XCTAssert(headers.contains(subject), "Mail header did not contain \(subject)")

        let mimeVersion = "MIME-VERSION: 1.0 (Swift-SMTP)"
        XCTAssert(headers.contains(mimeVersion), "Mail header did not contain \(mimeVersion)")

        let additionalHeader = "KEY: val"
        XCTAssert(headers.contains(additionalHeader), "Mail header did not contain \(additionalHeader)")
    }

    func testTakeLast1() {
        let arr = [a, b, ab]
        let last = arr.takeLast { $0.contains("a") }.0
        if let last = last {
            XCTAssertEqual(last, ab, "result: \(last) != expected: \(ab)")
        } else {
            XCTFail()
        }
    }

    func testTakeLast2() {
        let arr = [a, b, ab]
        let last = arr.takeLast { $0.contains("b") }.0
        if let last = last {
            XCTAssertEqual(last, b, "result: \(last) != expected: \(b)")
        } else {
            XCTFail()
        }
    }
}

// User
extension TestMiscellaneous {
    func testMimeNoName() {
        let user = User(email: "bob@gmail.com")
        let expected = "bob@gmail.com"
        XCTAssertEqual(user.mime, expected, "result: \(user.mime) != expected: \(expected)")
    }

    func testMimeWithName() {
        let user = User(name: "Bob", email: "bob@gmail.com")
        let expected = "=?UTF-8?Q?Bob?= <bob@gmail.com>"
        XCTAssertEqual(user.mime, expected, "result: \(user.mime) != expected: \(expected)")
    }
}

// Utils
extension TestMiscellaneous {
    func testBase64Encoded() {
        let result1 = randomText1.base64Encoded
        XCTAssertEqual(result1, randomText1Encoded, "result: \(result1) != expected: \(randomText1Encoded)")

        let result2 = randomText2.base64Encoded
        XCTAssertEqual(result2, randomText2Encoded, "result: \(result2) != expected: \(randomText2Encoded)")

        let result3 = randomText3.base64Encoded
        XCTAssertEqual(result3, randomText3Encoded, "result: \(result3) != expected: \(randomText3Encoded)")
    }

    func testMimeEncoded() {
        let result = "Water you up to?".mimeEncoded
        let expected = "=?UTF-8?Q?Water_you_up_to??="
        XCTAssertEqual(result, expected, "result: \(String(describing: result)) != expected: \(expected)")
    }
}
