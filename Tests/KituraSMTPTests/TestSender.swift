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
import KituraSMTP

#if os(Linux)
    import Dispatch
#endif

class TestSender: XCTestCase {
    static var allTests : [(String, (TestSender) -> () throws -> Void)] {
        return [
            ("testSendMail", testSendMail),
            ("testSendMultipleRecipients", testSendMultipleRecipients),
            ("testSendMailWithCc", testSendMailWithCc),
            ("testSendMailWithBcc", testSendMailWithBcc),
            ("testSendMultipleMails", testSendMultipleMails),
            ("testSendMailsConcurrently", testSendMailsConcurrently)
        ]
    }
    
    func testSendMail() {
        let mail = Mail(from: from, to: [to1], subject: "Simple email", text: text)
        smtp.send(mail) { (err) in
            XCTAssertNil(err)
            self.x.fulfill()
        }
        waitForExpectations(timeout: 10)
    }
    
    func testSendMultipleRecipients() {
        let mail = Mail(from: from, to: [to1, to2], subject: "Multiple recipients")
        smtp.send(mail) { (err) in
            XCTAssertNil(err)
            self.x.fulfill()
        }
        waitForExpectations(timeout: 10)
    }
    
    func testSendMailWithCc() {
        let mail = Mail(from: from, to: [to2], cc: [to1], subject: "Mail with Cc")
        smtp.send(mail) { (err) in
            XCTAssertNil(err)
            self.x.fulfill()
        }
        waitForExpectations(timeout: 10)
    }
    
    func testSendMailWithBcc() {
        let mail = Mail(from: from, to: [to2], bcc: [to1], subject: "Mail with Bcc")
        smtp.send(mail) { (err) in
            XCTAssertNil(err)
            self.x.fulfill()
        }
        waitForExpectations(timeout: 10)
    }
    
    func testSendMultipleMails() {
        let mail1 = Mail(from: from, to: [to1], subject: "Send multiple mails 1")
        let mail2 = Mail(from: from, to: [to1], subject: "Send multiple mails 2")
        smtp.send([mail1, mail2], progress: { (_, err) in
            XCTAssertNil(err)
        }) { (sent, failed) in
            XCTAssertEqual(sent.count, 2)
            XCTAssert(failed.isEmpty)
            self.x.fulfill()
        }
        waitForExpectations(timeout: 10)
    }
    
    func testSendMailsConcurrently() {
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        dispatchGroup.enter()
        
        let mail1 = Mail(from: from, to: [to1], subject: "Send mails concurrently 1")
        let mail2 = Mail(from: from, to: [to1], subject: "Send mails concurrently 2")

        smtp.send(mail1) { (err) in
            XCTAssertNil(err)
            dispatchGroup.leave()
        }
        
        smtp.send(mail2) { (err) in
            XCTAssertNil(err)
            dispatchGroup.leave()
        }
        
        dispatchGroup.wait()
        
        x.fulfill()
        waitForExpectations(timeout: 10)
    }
    
    var x: XCTestExpectation!
    
    override func setUp() {
        x = expectation(description: "")
    }
}
