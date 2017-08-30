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

#if os(Linux)
    import Dispatch
#endif

class TestDataSender: XCTestCase {
    static var allTests = [
        ("testDataCache", testDataCache),
        ("testFileCache", testFileCache),
        ("testHTMLCache", testHTMLCache),
        ("testSendData", testSendData),
        ("testSendFile", testSendFile),
        ("testSendHTML", testSendHTML),
        ("testSendHTMLAlternative", testSendHTMLAlternative),
        ("testSendMultipleAttachments", testSendMultipleAttachments),
        ("testSendNonASCII", testSendNonASCII),
        ("testSendRelatedAttachment", testSendRelatedAttachment)
    ]

    func testDataCache() throws {
        let x = self.expectation(description: #function)
        defer { waitForExpectations(timeout: testDuration) }

        let group = DispatchGroup()
        group.enter()

        var sender: Sender?

        try Login(hostname: hostname,
                  email: email,
                  password: password,
                  port: port,
                  ssl: ssl,
                  authMethods: authMethods,
                  domainName: domainName,
                  accessToken: nil,
                  timeout: timeout) { (loginResult) in
                    switch loginResult {
                    case .failure(_): XCTFail()
                    case .success(let socket):
                        let attachment = Attachment(data: data, mime: "application/json", name: "file.json")
                        let mail = Mail(from: from, to: [to], subject: #function, text: text, attachments: [attachment])
                        
                        sender = Sender(socket: socket, pending: [mail], progress: nil) { (sent, failed) in
                            XCTAssertEqual(sent.count, 1)
                            XCTAssertEqual(failed.count, 0)
                            group.leave()
                        }
                        sender?.send()
                    }
            }.login()
        
        group.wait()

        #if os(macOS)
            let cached = sender?.dataSender.cache.object(forKey: data as AnyObject)
            XCTAssertEqual(cached as? Data, data.base64EncodedData())
        #else
            let cached = sender?.dataSender.cache.object(forKey: NSData(data: data) as AnyObject)
            XCTAssertEqual(cached as? NSData, NSData(data: data.base64EncodedData()))
        #endif
        
        x.fulfill()
    }

    func testFileCache() throws {
        let x = self.expectation(description: #function)
        defer { waitForExpectations(timeout: testDuration) }

        let group = DispatchGroup()
        group.enter()

        var sender: Sender?

        try Login(hostname: hostname,
                  email: email,
                  password: password,
                  port: port,
                  ssl: ssl,
                  authMethods: authMethods,
                  domainName: domainName,
                  accessToken: nil,
                  timeout: timeout) { (loginResult) in
                    switch loginResult {
                    case .failure(_): XCTFail()
                    case .success(let socket):
                        let attachment = Attachment(filePath: imgFilePath)
                        let mail = Mail(from: from, to: [to], subject: #function, text: text, attachments: [attachment])

                        sender = Sender(socket: socket, pending: [mail], progress: nil) { (sent, failed) in
                            XCTAssertEqual(sent.count, 1)
                            XCTAssertEqual(failed.count, 0)
                            group.leave()
                        }
                        sender?.send()
                    }
            }.login()

        group.wait()

        guard let file = FileHandle(forReadingAtPath: imgFilePath) else {
            XCTFail()
            return
        }
        let data = file.readDataToEndOfFile().base64EncodedData()
        file.closeFile()

        #if os(macOS)
            let cached = sender?.dataSender.cache.object(forKey: imgFilePath as AnyObject)
            XCTAssertEqual(cached as? Data, data)
        #else
            let cached = sender?.dataSender.cache.object(forKey: NSString(string: imgFilePath) as AnyObject)
            XCTAssertEqual(cached as? NSData, NSData(data: data))
        #endif

        x.fulfill()
    }

    func testHTMLCache() throws {
        let x = self.expectation(description: #function)
        defer { waitForExpectations(timeout: testDuration) }

        let group = DispatchGroup()
        group.enter()

        var sender: Sender?

        try Login(hostname: hostname,
                  email: email,
                  password: password,
                  port: port,
                  ssl: ssl,
                  authMethods: authMethods,
                  domainName: domainName,
                  accessToken: nil,
                  timeout: timeout) { (loginResult) in
                    switch loginResult {
                    case .failure(_): XCTFail()
                    case .success(let socket):
                        let attachment = Attachment(htmlContent: html)
                        let mail = Mail(from: from, to: [to], subject: #function, text: text, attachments: [attachment])

                        sender = Sender(socket: socket, pending: [mail], progress: nil) { (sent, failed) in
                            XCTAssertEqual(sent.count, 1)
                            XCTAssertEqual(failed.count, 0)
                            group.leave()
                        }
                        sender?.send()
                    }
            }.login()

        group.wait()

        #if os(macOS)
            let cached = sender?.dataSender.cache.object(forKey: html as AnyObject)
            XCTAssertEqual(cached as? String, html.base64Encoded)
        #else
            let cached = sender?.dataSender.cache.object(forKey: NSString(string: html) as AnyObject)
            XCTAssertEqual(cached as? NSString, NSString(string: html.base64Encoded))
        #endif

        x.fulfill()
    }

    func testSendData() {
        let x = expectation(description: "Send mail with data attachment.")
        let dataAttachment = Attachment(data: data, mime: "application/json", name: "file.json")
        let mail = Mail(from: from, to: [to], subject: "Data attachment", text: text, attachments: [dataAttachment])
        smtp.send(mail) { (err) in
            XCTAssertNil(err, String(describing: err))
            x.fulfill()
        }
        waitForExpectations(timeout: testDuration)
    }

    func testSendFile() {
        let x = expectation(description: "Send mail with file attachment.")
        let fileAttachment = Attachment(filePath: imgFilePath)
        let mail = Mail(from: from, to: [to], subject: "File attachment", text: text, attachments: [fileAttachment])
        smtp.send(mail) { (err) in
            XCTAssertNil(err, String(describing: err))
            x.fulfill()
        }
        waitForExpectations(timeout: testDuration)
    }

    func testSendHTML() {
        let x = expectation(description: "Send mail with HTML attachment.")
        let htmlAttachment = Attachment(htmlContent: html, alternative: false)
        let mail = Mail(from: from, to: [to], subject: "HTML attachment", text: text, attachments: [htmlAttachment])
        smtp.send(mail) { (err) in
            XCTAssertNil(err, String(describing: err))
            x.fulfill()
        }
        waitForExpectations(timeout: testDuration)
    }

    func testSendHTMLAlternative() {
        let x = expectation(description: "Send mail with HTML as alternative to text.")
        let htmlAttachment = Attachment(htmlContent: html)
        let mail = Mail(from: from, to: [to], subject: "HTML alternative attachment", text: text, attachments: [htmlAttachment])
        smtp.send(mail) { (err) in
            XCTAssertNil(err, String(describing: err))
            x.fulfill()
        }
        waitForExpectations(timeout: testDuration)
    }

    func testSendMultipleAttachments() {
        let x = expectation(description: "Send mail with multiple attachments.")
        let fileAttachment = Attachment(filePath: imgFilePath)
        let htmlAttachment = Attachment(htmlContent: html, alternative: false)
        let mail = Mail(from: from, to: [to], subject: "Multiple attachments", text: text, attachments: [fileAttachment, htmlAttachment])
        smtp.send(mail) { (err) in
            XCTAssertNil(err, String(describing: err))
            x.fulfill()
        }
        waitForExpectations(timeout: testDuration)
    }

    func testSendNonASCII() {
        let x = expectation(description: "Send mail with non ASCII character.")
        let mail = Mail(from: from, to: [to], subject: "Non ASCII", text: "💦")
        smtp.send(mail) { (err) in
            XCTAssertNil(err, String(describing: err))
            x.fulfill()
        }
        waitForExpectations(timeout: testDuration)
    }

    func testSendRelatedAttachment() {
        let x = expectation(description: "Send mail with an attachment that references a related attachment.")
        let fileAttachment = Attachment(filePath: imgFilePath, additionalHeaders: ["CONTENT-ID": "megaman-pic"])
        let htmlAttachment = Attachment(htmlContent: "<html><img src=\"cid:megaman-pic\"/>\(text)</html>", relatedAttachments: [fileAttachment])
        let mail = Mail(from: from, to: [to], subject: "HTML with related attachment", text: text, attachments: [htmlAttachment])
        smtp.send(mail) { (err) in
            XCTAssertNil(err, String(describing: err))
            x.fulfill()
        }
        waitForExpectations(timeout: testDuration)
    }
}
