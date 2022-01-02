/**
 * Copyright Stephen Beitzel 2021
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

@testable import SwiftSMTP
import XCTest

class TestFoldUnfold: XCTestCase {
    let spaciousSubject = "Sample subject  with  extra whitespace inside"
    var mailMessage: Mail?

    // this is a base64 encoding of Package.swift
    let egregiousLine = "Ly8gc3dpZnQtdG9vbHMtdmVyc2lvbjo1LjAKCmltcG9ydCBQYWNrYWdlRGVzY3JpcHRpb24KCmxldCBwYWNrYWdlID0gUGFja2FnZSgKICAgIG5hbWU6ICJTd2lmdFNNVFAiLAogICAgcHJvZHVjdHM6IFsKICAgICAgICAubGlicmFyeSgKICAgICAgICAgICAgbmFtZTogIlN3aWZ0U01UUCIsCiAgICAgICAgICAgIHRhcmdldHM6IFsiU3dpZnRTTVRQIl0pLAogICAgICAgIF0sCiAgICBkZXBlbmRlbmNpZXM6IFsKICAgICAgICAucGFja2FnZSh1cmw6ICJodHRwczovL2dpdGh1Yi5jb20vS2l0dXJhL0JsdWVTb2NrZXQuZ2l0IiwgZnJvbTogIjIuMC4yIiksCiAgICAgICAgLnBhY2thZ2UodXJsOiAiaHR0cHM6Ly9naXRodWIuY29tL0tpdHVyYS9CbHVlU1NMU2VydmljZS5naXQiLCBmcm9tOiAiMi4wLjEiKSwKICAgICAgICAucGFja2FnZSh1cmw6ICJodHRwczovL2dpdGh1Yi5jb20vS2l0dXJhL0JsdWVDcnlwdG9yLmdpdCIsIGZyb206ICIyLjAuMSIpLAogICAgICAgIC5wYWNrYWdlKHVybDogImh0dHBzOi8vZ2l0aHViLmNvbS9LaXR1cmEvTG9nZ2VyQVBJLmdpdCIsIGZyb206ICIxLjkuMjAwIiksCiAgICAgICAgXSwKICAgIHRhcmdldHM6IFsKICAgICAgICAudGFyZ2V0KAogICAgICAgICAgICBuYW1lOiAiU3dpZnRTTVRQIiwKICAgICAgICAgICAgZGVwZW5kZW5jaWVzOiBbIlNvY2tldCIsICJTU0xTZXJ2aWNlIiwgIkNyeXB0b3IiLCAiTG9nZ2VyQVBJIl0pLAogICAgICAgIC50ZXN0VGFyZ2V0KAogICAgICAgICAgICBuYW1lOiAiU3dpZnRTTVRQVGVzdHMiLAogICAgICAgICAgICBkZXBlbmRlbmNpZXM6IFsiU3dpZnRTTVRQIl0pLAogICAgICAgIF0KKQo="

    override func setUpWithError() throws {
        let manyRecipients: [Mail.User] = Array.init(repeating: Mail.User(email: "some_recipient@dumbster.local"),
                                                     count: 30)
        let absurdlyLongEmail = Mail.User(name: "Unfortunate Joe",
                                          email: "unfortunate_joe_1234567890_123456789_123456783_123456784_123456785_123456786@dumbster.local")
        mailMessage = Mail(from: Mail.User(name: "Test User", email: "tester@dumbster.local"),
                           to: manyRecipients,
                           cc: [absurdlyLongEmail],
                           subject: spaciousSubject,
                           text: "Just some message",
                           additionalHeaders: ["X-OBNOXIOUS": egregiousLine,
                                               "X-SHORT": spaciousSubject])
    }

    // Here we test two things: 1) a short line will not be folded,
    // and 2) a line containing multiple consecutive whitespace characters
    // will not be changed.
    func testShortHeaderUnchanged() throws {
        let allHeaders = mailMessage!.headersString.split(separator: "\r\n")
        let unmodified = "X-SHORT: \(spaciousSubject)"
        for header in allHeaders where header.hasPrefix("X-SHORT") {
            XCTAssertEqual(String(header), unmodified)
        }
    }

    // This test looks at folding a long name plus email address, which won't
    // contain a comma. The fold should happen at the space between the name
    // and the email.
    func testAbsurdEmail() throws {
        let allHeaders = mailMessage!.headersString.split(separator: "\r\n")
        var foundCC = false
        for header in allHeaders {
            if foundCC {
                // we are now at the first line *after* the CC: line
                XCTAssertEqual(header, " <unfortunate_joe_1234567890_123456789_123456783_123456784_123456785_123456786@dumbster.local>")
                break
            } else  if header.hasPrefix("CC:") {
                foundCC = true
                XCTAssertEqual(header, "CC: \("Unfortunate Joe".mimeEncoded!)")
                continue
            }
        }
    }

    // This test looks at what happens when a header value does not
    // contain any spaces at all, and is thus unfoldable, while still
    // being longer than the recommended length.
    func testUnfoldableHeader() throws {
        let allHeaders = mailMessage!.headersString.split(separator: "\r\n")
        for header in allHeaders where header.hasPrefix("X-OBNOXIOUS") {
            XCTAssertEqual(header, "X-OBNOXIOUS: \(egregiousLine)")
        }
    }

    // This test looks at a long list of email addresses. There are plenty
    // of commas and whitespaces, so folding is possible. It should happen
    // at the whitespace, and not in the middle of an address.
    func testFoldOnWhitespace() throws {
        let allHeaders = mailMessage!.headersString.split(separator: "\r\n")
        for header in allHeaders where header.hasPrefix("TO: ") {
            print(header)
            XCTAssert(header.hasSuffix("some_recipient@dumbster.local,"))
        }
    }
}
