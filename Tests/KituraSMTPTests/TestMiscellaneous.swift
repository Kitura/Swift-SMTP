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
@testable import KituraSMTP

class TestMiscellaneous: XCTestCase {
    static var allTests: [(String, (TestMiscellaneous) -> () throws -> Void)] {
        return [
            ("testMailHeaders", testMailHeaders),
            ("testDateFormatter", testDateFormatter),
            ("testTakeLast1", testTakeLast1),
            ("testTakeLast1", testTakeLast1),
            ("testMimeWithName", testMimeWithName),
            ("testMimeNoName", testMimeNoName),
            ("testMimeEncoded", testMimeEncoded),
            ("testBase64Encoded", testBase64Encoded)
        ]
    }
    
    let a = ["a"]
    let b = ["b"]
    let ab = ["a", "c"]
}

// Mail
extension TestMiscellaneous {
    func testMailHeaders() {
        let headers = Mail(from: from, to: [to], cc: [to2], subject: "Test", text: text, additionalHeaders: ["key": "val"]).headers
        XCTAssert(headers.contains("TO: =?UTF-8?Q?Megaman?= <kiturasmtp@gmail.com>"))
        XCTAssert(headers.contains("CC: =?UTF-8?Q?Roll?= <kiturasmtp2@gmail.com>"))
        XCTAssert(headers.contains("SUBJECT: =?UTF-8?Q?Test?="))
        XCTAssert(headers.contains("MIME-VERSION: 1.0 (Kitura-SMTP)"))
        XCTAssert(headers.contains("KEY: val"))
    }
    
    func testDateFormatter() {
        let date = Date(timeIntervalSince1970: 0)
        let formatter = DateFormatter.smtpDateFormatter
        formatter.timeZone = TimeZone(secondsFromGMT: 3600 * 9)
        XCTAssertEqual(formatter.string(from: date), "Thu, 1 Jan 1970 09:00:00 +0900")
    }
    
    func testTakeLast1() {
        let arr = [a, b, ab]
        let last = arr.takeLast { $0.contains("a") }.0
        if let last = last {
            XCTAssertEqual(last, ["a", "c"])
        } else {
            XCTFail()
        }
    }
    
    func testTakeLast2() {
        let arr = [a, b, ab]
        let last = arr.takeLast { $0.contains("b") }.0
        if let last = last {
            XCTAssertEqual(last, ["b"])
        } else {
            XCTFail()
        }
    }
}

// User
extension TestMiscellaneous {
    func testMimeWithName() {
        let user = User(name: "Bob", email: "bob@gmail.com")
        XCTAssertEqual(user.mime, "=?UTF-8?Q?Bob?= <bob@gmail.com>")
    }
    
    func testMimeNoName() {
        let user = User(email: "bob@gmail.com")
        XCTAssertEqual(user.mime, "bob@gmail.com")
    }
}

// Utils
extension TestMiscellaneous {
    func testMimeEncoded() {
        XCTAssertEqual("Water you up to?".mimeEncoded, "=?UTF-8?Q?Water_you_up_to??=")
    }
    
    func testBase64Encoded() {
        XCTAssertEqual(randomText1.base64Encoded, randomText1Encoded)
        XCTAssertEqual(randomText2.base64Encoded, randomText2Encoded)
        XCTAssertEqual(randomText3.base64Encoded, randomText3Encoded)
    }
}
