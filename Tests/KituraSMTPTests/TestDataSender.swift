import XCTest
import KituraSMTP

class TestDataSender: XCTestCase {
    static var allTests : [(String, (TestDataSender) -> () throws -> Void)] {
        return [
            ("testSendNonASCII", testSendNonASCII),
            ("testSendFile", testSendFile),
            ("testSendHTMLAlternative", testSendHTMLAlternative),
            ("testSendHTML", testSendHTML),
            ("testSendData", testSendData),
            ("testSendRelatedAttachment", testSendRelatedAttachment),
            ("testSendMultipleAttachments", testSendMultipleAttachments)
        ]
    }
    
    func testSendNonASCII() {
        let mail = Mail(from: user, to: [user], subject: "Non ASCII", text: "💦")
        smtp.send(mail) { (err) in
            XCTAssertNil(err)
            self.x.fulfill()
        }
        waitForExpectations(timeout: 10)
    }
    
    func testSendFile() {
        let fileAttachment = Attachment(filePath: imgFilePath)
        let mail = Mail(from: user, to: [user], subject: "File attachment", attachments: [fileAttachment])
        smtp.send(mail) { (err) in
            XCTAssertNil(err)
            self.x.fulfill()
        }
        waitForExpectations(timeout: 10)
    }
    
    func testSendHTMLAlternative() {
        let htmlAttachment = Attachment(htmlContent: html)
        let mail = Mail(from: user, to: [user], subject: "HTML alternative attachment", text: text, attachments: [htmlAttachment])
        smtp.send(mail) { (err) in
            XCTAssertNil(err)
            self.x.fulfill()
        }
        waitForExpectations(timeout: 10)
    }
    
    func testSendHTML() {
        let htmlAttachment = Attachment(htmlContent: html, alternative: false)
        let mail = Mail(from: user, to: [user], subject: "HTML attachment", text: text, attachments: [htmlAttachment])
        smtp.send(mail) { (err) in
            XCTAssertNil(err)
            self.x.fulfill()
        }
        waitForExpectations(timeout: 10)
    }
    
    func testSendData() {
        let data = "{\"key\": \"hello world\"}".data(using: .utf8)!
        let attachment = Attachment(data: data, mime: "text/plain", name: "file.txt")
        let mail = Mail(from: user, to: [user], subject: "Data attachment", attachments: [attachment])
        smtp.send(mail) { (err) in
            XCTAssertNil(err)
            self.x.fulfill()
        }
        waitForExpectations(timeout: 10)
    }
    
    func testSendRelatedAttachment() {
        let fileAttachment = Attachment(filePath: imgFilePath, additionalHeaders: ["CONTENT-ID": "megaman-pic"])
        let htmlAttachment = Attachment(htmlContent: "<html><img src=\"cid:megaman-pic\"/></html>", related: [fileAttachment])
        let mail = Mail(from: user, to: [user], subject: "HTML with related attachment", attachments: [htmlAttachment])
        smtp.send(mail) { (err) in
            XCTAssertNil(err)
            self.x.fulfill()
        }
        waitForExpectations(timeout: 10)
    }
    
    func testSendMultipleAttachments() {
        let fileAttachment = Attachment(filePath: imgFilePath)
        let htmlAttachment = Attachment(htmlContent: html, alternative: false)
        let mail = Mail(from: user, to: [user], subject: "Multiple attachments", text: text, attachments: [fileAttachment, htmlAttachment])
        smtp.send(mail) { (err) in
            XCTAssertNil(err)
            self.x.fulfill()
        }
        waitForExpectations(timeout: 10)
    }
    
    var x: XCTestExpectation!
    override func setUp() { x = expectation(description: "") }
}
