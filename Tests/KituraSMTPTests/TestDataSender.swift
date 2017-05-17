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

class TestDataSender: XCTestCase {
    static var allTests = [
        ("testSendNonASCII", testSendNonASCII),
        ("testSendFile", testSendFile),
        ("testSendHTMLAlternative", testSendHTMLAlternative),
        ("testSendHTML", testSendHTML),
        ("testSendData", testSendData),
        ("testSendRelatedAttachment", testSendRelatedAttachment),
        ("testSendMultipleAttachments", testSendMultipleAttachments),
        ("testFileCache", testFileCache),
        ("testHTMLCache", testHTMLCache),
        ("testDataCache", testDataCache)
    ]

    func testSendNonASCII() {
        let x = expectation(description: "Send mail with non ASCII character.")
        let mail = Mail(from: from, to: [to], subject: "Non ASCII", text: "💦")
        smtp.send(mail) { (err) in
            XCTAssertNil(err, String(describing: err))
            x.fulfill()
        }
        waitForExpectations(timeout: testDuration)
    }

    func testSendFile() {
        let x = expectation(description: "Send mail with file attachment.")
        let fileAttachment = Attachment(filePath: imgFilePath)
        let mail = Mail(from: from, to: [to], subject: "File attachment", attachments: [fileAttachment])
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

    func testSendData() {
        let x = expectation(description: "Send mail with data attachment.")
        let data = "{\"key\": \"hello world\"}".data(using: .utf8)!
        let dataAttachment = Attachment(data: data, mime: "application/json", name: "file.json")
        let mail = Mail(from: from, to: [to], subject: "Data attachment", attachments: [dataAttachment])
        smtp.send(mail) { (err) in
            XCTAssertNil(err, String(describing: err))
            x.fulfill()
        }
        waitForExpectations(timeout: testDuration)
    }

    func testSendRelatedAttachment() {
        let x = expectation(description: "Send mail with an attachment that references a related attachment.")
        let fileAttachment = Attachment(filePath: imgFilePath, additionalHeaders: ["CONTENT-ID": "megaman-pic"])
        let htmlAttachment = Attachment(htmlContent: "<html><img src=\"cid:megaman-pic\"/>This text is HTML</html>", relatedAttachments: [fileAttachment])
        let mail = Mail(from: from, to: [to], subject: "HTML with related attachment", attachments: [htmlAttachment])
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

    func testFileCache() throws {
        let expectation = self.expectation(description: "\(#function)")
        defer {
            waitForExpectations(timeout: testDuration) { (error) in
                if let error = error {
                    XCTFail("\(error)")
                }
            }
        }

        let group = DispatchGroup()
        group.enter()

        var sender: Sender?

        try Login(hostname: hostname,
                  user: user,
                  password: password,
                  port: port,
                  ssl: ssl,
                  authMethods: authMethods,
                  domainName: domainName,
                  accessToken: nil,
                  timeout: timeout) { (socket, error) in

                    XCTAssertNil(error)

                    if let socket = socket {
                        let attachment = Attachment(filePath: imgFilePath)
                        let mail = Mail(from: from, to: [to], subject: #function, attachments: [attachment])

                        sender = Sender(socket: socket, pending: [mail, mail], progress: nil) { (sent, failed) in
                            XCTAssertEqual(sent.count, 2)
                            XCTAssertEqual(failed.count, 0)
                            group.leave()
                        }
                        sender?.send()
                    }

            }.login()

        group.wait()

        #if os(macOS)
            let cachedFile = sender?.dataSender.cache.object(forKey: imgFilePath as AnyObject)
        #else
            let cachedFile = sender?.dataSender.cache.object(forKey: NSString(string: imgFilePath) as AnyObject)
        #endif
        XCTAssertNotNil(cachedFile)

        expectation.fulfill()
    }

    func testHTMLCache() throws {
        let expectation = self.expectation(description: "\(#function)")
        defer {
            waitForExpectations(timeout: testDuration) { (error) in
                if let error = error {
                    XCTFail("\(error)")
                }
            }
        }

        let group = DispatchGroup()
        group.enter()

        var sender: Sender?

        try Login(hostname: hostname,
                  user: user,
                  password: password,
                  port: port,
                  ssl: ssl,
                  authMethods: authMethods,
                  domainName: domainName,
                  accessToken: nil,
                  timeout: timeout) { (socket, error) in

                    XCTAssertNil(error)

                    if let socket = socket {
                        let attachment = Attachment(htmlContent: html)
                        let mail = Mail(from: from, to: [to], subject: #function, attachments: [attachment])

                        sender = Sender(socket: socket, pending: [mail, mail], progress: nil) { (sent, failed) in
                            XCTAssertEqual(sent.count, 2)
                            XCTAssertEqual(failed.count, 0)
                            group.leave()
                        }
                        sender?.send()
                    }

            }.login()

        group.wait()

        #if os(macOS)
            let cachedFile = sender?.dataSender.cache.object(forKey: html as AnyObject)
        #else
            let cachedFile = sender?.dataSender.cache.object(forKey: NSString(string: html) as AnyObject)
        #endif
        XCTAssertNotNil(cachedFile)

        expectation.fulfill()
    }

    func testDataCache() throws {
        let expectation = self.expectation(description: "\(#function)")
        defer {
            waitForExpectations(timeout: testDuration) { (error) in
                if let error = error {
                    XCTFail("\(error)")
                }
            }
        }

        let group = DispatchGroup()
        group.enter()

        var sender: Sender?
        let data = "{\"key\": \"hello world\"}".data(using: .utf8)!

        try Login(hostname: hostname,
                  user: user,
                  password: password,
                  port: port,
                  ssl: ssl,
                  authMethods: authMethods,
                  domainName: domainName,
                  accessToken: nil,
                  timeout: timeout) { (socket, error) in

                    XCTAssertNil(error)

                    if let socket = socket {
                        let attachment = Attachment(data: data, mime: "application/json", name: "file.json")
                        let mail = Mail(from: from, to: [to], subject: #function, attachments: [attachment])

                        sender = Sender(socket: socket, pending: [mail, mail], progress: nil) { (sent, failed) in
                            XCTAssertEqual(sent.count, 2)
                            XCTAssertEqual(failed.count, 0)
                            group.leave()
                        }
                        sender?.send()
                    }
                    
            }.login()
        
        group.wait()

        #if os(macOS)
            let cachedFile = sender?.dataSender.cache.object(forKey: data as AnyObject)
        #else
            let cachedFile = sender?.dataSender.cache.object(forKey: NSData(data: data) as AnyObject)
        #endif
        XCTAssertNotNil(cachedFile)
        
        expectation.fulfill()
    }
}
