import XCTest
import KituraSMTP

class TestSend: XCTestCase {
    static var allTests : [(String, (TestSend) -> () throws -> Void)] {
        return [
            ("testSendMail", testSendMail),
            ("testSendMultipleRecipients", testSendMultipleRecipients),
            ("testSendMailWithCc", testSendMailWithCc),
            ("testSendMailWithBcc", testSendMailWithBcc),
            ("testSendMultipleMails", testSendMultipleMails)
        ]
    }

    let junoUser = "kitura-smtp@juno.com"
    let gmailSMTP = "smtp.gmail.com"
    let gmailUser = "kiturasmtp@gmail.com"
    let password = "ibm12345"

    let from = "Dr. Light"
    let to = "Megaman"
    let subject = "Humans and robots living together in harmony and equality."
    let text = "That was my ultimate wish."
    
    var chainFilePath: String?
    let chainFilePassword = "kitura"
    let selfSignedCerts = true
    
    func getChainFilePath() {
        if chainFilePath != nil { return }
        var pathToTests = #file
        if pathToTests.hasSuffix("TestSend.swift") {
            pathToTests = pathToTests.replacingOccurrences(of: "TestSend.swift", with: "")
        }
        chainFilePath = URL(fileURLWithPath: "\(pathToTests)\("cert.pfx")").path
    }
    
    var x: XCTestExpectation?
    
    func testSendMail() {
        x = expectation(description: "Send an email.")
        getChainFilePath()
        
        let smtp = SMTP(hostname: gmailSMTP, user: gmailUser, password: password, chainFilePath: chainFilePath, chainFilePassword: chainFilePassword, selfSignedCerts: selfSignedCerts)
        let from = User(name: self.from, email: gmailUser)
        let to = User(name: self.to, email: gmailUser)
        let mail = Mail(from: from, to: [to], subject: subject, text: text)
        
        smtp.send(mail) { (err) in
            XCTAssertNil(err)
            self.x?.fulfill()
        }
        
        waitForExpectations(timeout: 5) { (_) in }
    }
    
    func testSendMultipleRecipients() {
        x = expectation(description: "Send mail to multiple recipients.")
        getChainFilePath()
        
        let smtp = SMTP(hostname: gmailSMTP, user: gmailUser, password: password, chainFilePath: chainFilePath, chainFilePassword: chainFilePassword, selfSignedCerts: selfSignedCerts)
        let from = User(name: self.from, email: gmailUser)
        let to1 = User(name: self.to, email: gmailUser)
        let to2 = User(name: self.to, email: junoUser)
        let mail = Mail(from: from, to: [to1, to2], subject: subject, text: text)
        
        smtp.send(mail) { (err) in
            XCTAssertNil(err)
            self.x?.fulfill()
        }
        
        waitForExpectations(timeout: 5) { (_) in }
    }
    
    func testSendMailWithCc() {
        x = expectation(description: "Send mail with Cc.")
        getChainFilePath()
        
        let smtp = SMTP(hostname: gmailSMTP, user: gmailUser, password: password, chainFilePath: chainFilePath, chainFilePassword: chainFilePassword, selfSignedCerts: selfSignedCerts)
        let from = User(name: self.from, email: gmailUser)
        let to1 = User(name: self.to, email: gmailUser)
        let to2 = User(name: self.to, email: junoUser)
        let mail = Mail(from: from, to: [to2], cc: [to1], subject: subject, text: text)
        
        smtp.send(mail) { (err) in
            XCTAssertNil(err)
            self.x?.fulfill()
        }
        
        waitForExpectations(timeout: 5) { (_) in }
    }
    
    func testSendMailWithBcc() {
        x = expectation(description: "Send mail with Bcc.")
        getChainFilePath()
        
        let smtp = SMTP(hostname: gmailSMTP, user: gmailUser, password: password, chainFilePath: chainFilePath, chainFilePassword: chainFilePassword, selfSignedCerts: selfSignedCerts)
        let from = User(name: self.from, email: gmailUser)
        let to1 = User(name: self.to, email: gmailUser)
        let to2 = User(name: self.to, email: junoUser)
        let mail = Mail(from: from, to: [to1], bcc: [to2], subject: subject, text: text)
        
        smtp.send(mail) { (err) in
            XCTAssertNil(err)
            self.x?.fulfill()
        }
        
        waitForExpectations(timeout: 5) { (_) in }
    }
    
    func testSendMultipleMails() {
        x = expectation(description: "Send multiple mails.")
        getChainFilePath()
        
        let smtp = SMTP(hostname: gmailSMTP, user: gmailUser, password: password, chainFilePath: chainFilePath, chainFilePassword: chainFilePassword, selfSignedCerts: selfSignedCerts)
        let from = User(name: self.from, email: gmailUser)
        let to = User(name: self.to, email: gmailUser)
        let mail1 = Mail(from: from, to: [to], subject: subject, text: text)
        let mail2 = Mail(from: from, to: [to], subject: subject, text: text)
        
        smtp.send([mail1, mail2], progress: { (_, err) in
            XCTAssertNil(err)
        }) { (sent, failed) in
            XCTAssertEqual(sent.count, 2)
            XCTAssert(failed.isEmpty)
            self.x?.fulfill()
        }
        
        waitForExpectations(timeout: 5) { (_) in }
    }
}
