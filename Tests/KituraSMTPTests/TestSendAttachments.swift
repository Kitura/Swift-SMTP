//
//  TestSendAttachments.swift
//  KituraSMTP
//
//  Created by Quan Vo on 3/21/17.
//
//

import XCTest
import KituraSMTP

class TestSendAttachments: XCTestCase {
    static var allTests : [(String, (TestSendAttachments) -> () throws -> Void)] {
        return [
        ]
    }
    
    let gmailSMTP = "smtp.gmail.com"
    let gmailUser = "kiturasmtp@gmail.com"
    let password = "ibm12345"
    
    var chainFilePath: String {
        var pathToTests = #file
        if pathToTests.hasSuffix("TestSendAttachments.swift") {
            pathToTests = pathToTests.replacingOccurrences(of: "TestSendAttachments.swift", with: "")
        }
        return URL(fileURLWithPath: "\(pathToTests)\("cert.pfx")").path
    }
    let chainFilePassword = "kitura"
    let selfSignedCerts = true
    
    let from = "Dr. Light"
    let to = "Megaman"
    let subject = "Humans and robots living together in harmony and equality."
    let text = "That was my ultimate wish."
    
    var xPicFilePath: String {
        var pathToTests = #file
        if pathToTests.hasSuffix("TestSendAttachments.swift") {
            pathToTests = pathToTests.replacingOccurrences(of: "TestSendAttachments.swift", with: "")
        }
        return URL(fileURLWithPath: "\(pathToTests)\("x.png")").path
    }
    
    var x: XCTestExpectation?
    
    func testSendFile() {
        x = expectation(description: "Send email with file attachment.")
        
        let smtp = SMTP(hostname: gmailSMTP, user: gmailUser, password: password, chainFilePath: chainFilePath, chainFilePassword: chainFilePassword, selfSignedCerts: selfSignedCerts)
        let user = User(name: to, email: gmailUser)
        let file = Attachment(filePath: xPicFilePath, inline: true)
        let mail = Mail(from: user, to: [user], subject: subject, text: text, attachments: [file])
        smtp.send(mail) { (err) in
            XCTAssertNil(err)
            self.x?.fulfill()
        }
        
        waitForExpectations(timeout: 10) { (_) in }
    }
    
    func testSendHTML() {
        x = expectation(description: "Send email with HTML attachment.")
        
        let smtp = SMTP(hostname: gmailSMTP, user: gmailUser, password: password, chainFilePath: chainFilePath, chainFilePassword: chainFilePassword, selfSignedCerts: selfSignedCerts)
        let user = User(name: to, email: gmailUser)
        let html = Attachment(htmlContent: "<html><h1>Hi</h1></html>", alternative: false)
        let mail = Mail(from: user, to: [user], subject: subject, text: text, attachments: [html])
        smtp.send(mail) { (err) in
            XCTAssertNil(err)
            self.x?.fulfill()
        }
        
        waitForExpectations(timeout: 10) { (_) in }
    }
    
    
}
