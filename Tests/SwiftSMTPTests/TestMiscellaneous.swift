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
        ("testBase64Encoded", testBase64Encoded),
        ("testMimeEncoded", testMimeEncoded),
        ("testDateFormatter", testDateFormatter),
        ("testMailHeaders", testMailHeaders),
        ("testMimeNoName", testMimeNoName),
        ("testMimeWithName", testMimeWithName)
    ]
}

// Common
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
        let headers = Mail(from: from, to: [to], cc: [to2], subject: "Test", text: text, additionalHeaders: ["header": "val"]).headersString

        let to_ = "TO: =?UTF-8?Q?Megaman?= <\(email)>"
        XCTAssert(headers.contains(to_), "Mail header did not contain \(to_)")

        let cc_ = "CC: =?UTF-8?Q?Roll?= <\(email)>"
        XCTAssert(headers.contains(cc_), "Mail header did not contain \(cc_)")

        let subject = "SUBJECT: =?UTF-8?Q?Test?="
        XCTAssert(headers.contains(subject), "Mail header did not contain \(subject)")

        let mimeVersion = "MIME-VERSION: 1.0 (Swift-SMTP)"
        XCTAssert(headers.contains(mimeVersion), "Mail header did not contain \(mimeVersion)")

        let messageIdSearchResponse = findMessageId(inString: headers)
        XCTAssert(validMessageIdMsg == messageIdSearchResponse, messageIdSearchResponse)

        XCTAssert(headers.contains("HEADER"), "Mail header did not contain \"header\".")
        XCTAssert(headers.contains("val"), "Mail header did not contain \"val\".")
    }

    private func findMessageId(inString compareString: String) -> String {
        let messageIdHeaderPrefix = "MESSAGE-ID: <"
        // example uuid: E621E1F8-C36C-495A-93FC-0C247A3E6E5F
        let uuidRegEx = "[A-Z0-9]{8}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{12}"
        let messageIdHeaderSuffix = ".Swift-SMTP@\(senderEmailDomain)>"
        let regexPattern = "\(messageIdHeaderPrefix)\(uuidRegEx)\(messageIdHeaderSuffix)"

        guard let regex = try? NSRegularExpression(pattern: regexPattern, options: .anchorsMatchLines) else {
            return "Unable to create Regular Expression object"
        }

        let rangeLocation = 0
        let rangeLength = NSString(string: compareString).length
        let searchRange = NSRange(location: rangeLocation, length: rangeLength)

        // run the regex
        let matches = regex.matches(in: compareString, options: .withoutAnchoringBounds, range: searchRange)

        switch matches.count {
        case 0:
            return invalidMessageIdMsg
        case 1:
            return validMessageIdMsg
        default:
            return multipleMessageIdsMsg
        }
    }
}

// User
extension TestMiscellaneous {
    func testMimeNoName() {
        let user = Mail.User(email: "bob@gmail.com")
        let expected = "bob@gmail.com"
        XCTAssertEqual(user.mime, expected, "result: \(user.mime) != expected: \(expected)")
    }

    func testMimeWithName() {
        let user = Mail.User(name: "Bob", email: "bob@gmail.com")
        let expected = "=?UTF-8?Q?Bob?= <bob@gmail.com>"
        XCTAssertEqual(user.mime, expected, "result: \(user.mime) != expected: \(expected)")
    }
}
