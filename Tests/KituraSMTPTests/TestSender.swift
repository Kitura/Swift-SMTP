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

#if os(Linux)
    import Dispatch
#endif

class TestSender: XCTestCase {
    static var allTests: [(String, (TestSender) -> () throws -> Void)] {
        return [
            ("testSendMail", testSendMail),
            ("testSendMultipleRecipients", testSendMultipleRecipients),
            ("testSendMailWithCc", testSendMailWithCc),
            ("testSendMailWithBcc", testSendMailWithBcc),
            ("testSendMultipleMails", testSendMultipleMails),
            ("testSendMailsConcurrently", testSendMailsConcurrently),
            ("testBadEmail", testBadEmail),
            ("testSendMultipleMailsWithFail", testSendMultipleMailsWithFail),
            ("testIsValidEmail", testIsValidEmail)
        ]
    }

    func testSendMail() {
        let x = expectation(description: "Send a simple email.")
        let mail = Mail(from: from, to: [to2], subject: "Simple email", text: text)
        smtp.send(mail) { (err) in
            XCTAssertNil(err, String(describing: err))
            x.fulfill()
        }
        waitForExpectations(timeout: testDuration)
    }

    func testSendMultipleRecipients() {
        let x = expectation(description: "Send a single mail to multiple recipients.")
        let mail = Mail(from: from, to: [to, to2], subject: "Multiple recipients")
        smtp.send(mail) { (err) in
            XCTAssertNil(err, String(describing: err))
            x.fulfill()
        }
        waitForExpectations(timeout: testDuration)
    }

    func testSendMailWithCc() {
        let x = expectation(description: "Send mail with Cc.")
        let mail = Mail(from: from, to: [to], cc: [to2], subject: "Mail with Cc")
        smtp.send(mail) { (err) in
            XCTAssertNil(err, String(describing: err))
            x.fulfill()
        }
        waitForExpectations(timeout: testDuration)
    }

    func testSendMailWithBcc() {
        let x = expectation(description: "Send mail with Bcc.")
        let mail = Mail(from: from, to: [to], bcc: [to2], subject: "Mail with Bcc")
        smtp.send(mail) { (err) in
            XCTAssertNil(err, String(describing: err))
            x.fulfill()
        }
        waitForExpectations(timeout: testDuration)
    }

    func testSendMultipleMails() {
        let x = expectation(description: "Send multiple mails with one call to `send`.")
        let mail1 = Mail(from: from, to: [to], subject: "Send multiple mails 1")
        let mail2 = Mail(from: from, to: [to], subject: "Send multiple mails 2")
        smtp.send([mail1, mail2], progress: { (_, err) in
            XCTAssertNil(err, String(describing: err))
        }) { (sent, failed) in
            XCTAssert(failed.isEmpty, "Some mails failed to send.")
            XCTAssertEqual(sent.count, 2, "2 mails should have been sent.")
            x.fulfill()
        }
        waitForExpectations(timeout: testDuration)
    }

    func testSendMailsConcurrently() {
        let x = expectation(description: "Send multiple mails concurrently with seperate calls to `send`.")
        let mail1 = Mail(from: from, to: [to], subject: "Send mails concurrently 1")
        let mail2 = Mail(from: from, to: [to], subject: "Send mails concurrently 2")
        let mails = [mail1, mail2]
        let group = DispatchGroup()

        for mail in mails {
            group.enter()

            smtp.send(mail) { (err) in
                XCTAssertNil(err, String(describing: err))
                group.leave()
            }
        }

        group.wait()
        x.fulfill()
        waitForExpectations(timeout: testDuration)
    }

    func testBadEmail() {
        let x = expectation(description: "Send a mail that will fail because of an invalid receiving address.")
        let user = User(email: "")
        let mail = Mail(from: user, to: [user])
        smtp.send(mail) { (err) in
            XCTAssertNotNil(err, "Sending mail to an invalid email address should return an error, but return nil.")
            x.fulfill()
        }
        waitForExpectations(timeout: testDuration)
    }

    func testSendMultipleMailsWithFail() {
        let x = expectation(description: "Send two mails, one of which will fail.")
        let badUser = User(email: "")
        let badMail = Mail(from: from, to: [badUser])
        let goodMail = Mail(from: from, to: [to], subject: "Send multiple mails with fail")

        smtp.send([badMail, goodMail]) { (sent, failed) in
            guard sent.count == 1 && failed.count == 1 else {
                XCTFail("Send did not complete with 1 mail sent and 1 mail failed.")
                return
            }
            XCTAssertEqual(sent[0].id, goodMail.id, "Valid email was not sent.")
            XCTAssertEqual(failed[0].0.id, badMail.id, "Invalid email returned does not match the invalid email sent.")
            XCTAssertNotNil(failed[0].1, "Invalid email did not return an error when sending.")
            x.fulfill()
        }

        waitForExpectations(timeout: testDuration)
    }

    func testIsValidEmail() throws {
        XCTAssert(try user.isValidEmail(), "\(user) should be a valid email.")
        XCTAssertFalse(try "".isValidEmail(), "Blank email should be in invalid email.")
        XCTAssertFalse(try "a".isValidEmail(), "`a` should be in invalid email.")
        XCTAssertFalse(try "@gmail.com".isValidEmail(), "`@gmail.com` should be in invalid email.")
        XCTAssertFalse(try "user@.com".isValidEmail(), "`user@.com` should be in invalid email.")
        XCTAssertFalse(try "user@user".isValidEmail(), "`user@user` should be in invalid email.")
        XCTAssertFalse(try "user@user.a".isValidEmail(), "`user@user.a` should be in invalid email.")
        XCTAssertFalse(try "user@user.".isValidEmail(), "`user@user.` should be in invalid email.")
    }
}
