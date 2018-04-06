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

class TestSMTPSocket: XCTestCase {
    static var allTests: [(String, (TestSMTPSocket) -> () throws -> Void)] {
        return [
            ("testGetResponseCode", testGetResponseCode),
            ("testGetResponseCodeBadResponse", testGetResponseCodeBadResponse),
            ("testGetResponseCodeBlankReponse", testGetResponseCodeBlankReponse),
            ("testGetResponseMessageGood", testGetResponseMessageGood),
            ("testGetResponseMessageTooShort", testGetResponseMessageTooShort),
            ("testParseResponsesGood", testParseResponsesGood),
            ("testParseResponsesBad", testParseResponsesBad)
        ]
    }
}

extension TestSMTPSocket {
    func testGetResponseCode() throws {
        let responseCode = try SMTPSocket.getResponseCode("250-smtp.gmail.com at your service, [66.68.56.204]", command: .ehlo(""))
        let expected = ResponseCode(250)
        XCTAssertEqual(responseCode, expected, "result: \(responseCode) != expected: \(expected)")
    }

    func testGetResponseCodeBadResponse() {
        do {
            _ = try SMTPSocket.getResponseCode("250-SIZE 35882577", command: .starttls)
        } catch {
            guard let err = error as? SMTPError, case .badResponse = err else {
                XCTFail("Error should be SMTPError.badResponse but received no error or incorrect error.")
                return
            }
        }
    }

    func testGetResponseCodeBlankReponse() {
        do {
            _ = try SMTPSocket.getResponseCode("", command: .auth(.cramMD5, "credentials"))
        } catch {
            guard let err = error as? SMTPError, case .badResponse = err else {
                XCTFail("Error should be SMTPError.badResponse but received no error or incorrect error.")
                return
            }
        }
    }
}

extension TestSMTPSocket {
    func testGetResponseMessageGood() {
        let responseMessage = SMTPSocket.getResponseMessage("250 OK")
        XCTAssertEqual(responseMessage, "OK", "result: \(responseMessage) != expected: \"OK\"")
    }

    func testGetResponseMessageTooShort() {
        let responseMessage = SMTPSocket.getResponseMessage("NO")
        XCTAssertEqual(responseMessage, "", "result: \(responseMessage) != expected: \"\"")
    }
}

extension TestSMTPSocket {
    func testParseResponsesGood() throws {
        let ehloResponsesGood = "250 OK\(CRLF)250 GREAT\(CRLF)"
        let responses = try SMTPSocket.parseResponses(ehloResponsesGood, command: .ehlo(domainName))
        guard responses.count == 2 else {
            XCTFail("Should return 2 responses but returned \(responses.count)")
            return
        }
        XCTAssertEqual(responses[0].response, "250 OK", "First response: \(responses[0].response) != expected \"250 OK\"")
        XCTAssertEqual(responses[1].response, "250 GREAT", "Second response: \(responses[1].response) != expected \"250 GREAT\"")
    }

    func testParseResponsesBad() {
        let ehloResponsesBad = "999 BAD"
        do {
            _ = try SMTPSocket.parseResponses(ehloResponsesBad, command: .ehlo(domainName))
        } catch {
            guard let err = error as? SMTPError, case .badResponse = err else {
                XCTFail("Should return SMTPError.badResponse, but returned different error or no error.")
                return
            }
        }
    }
}
