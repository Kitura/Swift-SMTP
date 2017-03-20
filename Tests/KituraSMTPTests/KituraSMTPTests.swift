import XCTest
@testable import KituraSMTP

class KituraSMTPTests: XCTestCase {
    static var allTests : [(String, (KituraSMTPTests) -> () throws -> Void)] {
        return [
//            ("testSendMailCramMD5", testSendMailCramMD5),
            ("testSendMailLogin", testSendMailLogin),
            ("testSendMailPlain", testSendMailPlain),
            ("testXOAuth2Encoding", testXOAuth2Encoding),
            ("testSendMultipleRecipients", testSendMultipleRecipients),
            ("testSendMailWithCc", testSendMailWithCc),
            ("testSendMailWithBcc", testSendMailWithBcc),
            ("testSendMultipleMails", testSendMultipleMails)
        ]
    }

    let junoSMTP = "smtp.juno.com"
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
        if pathToTests.hasSuffix("KituraSMTPTests.swift") {
            pathToTests = pathToTests.replacingOccurrences(of: "KituraSMTPTests.swift", with: "")
        }
        chainFilePath = URL(fileURLWithPath: "\(pathToTests)\("cert.pfx")").path
    }
    
    var x: XCTestExpectation?
    
    // NOTE: Running this test too many times will get this Juno account flagged
    //       for spamming.
//    func testSendMailCramMD5() {
//        x = expectation(description: "Send email through CRAM-MD5 auth.")
//
//        let smtp = SMTP(hostname: junoSMTP, user: junoUser, password: password, authMethods: [.cramMD5])
//        let from = User(name: self.from, email: junoUser)
//        let to = User(name: self.to, email: junoUser)
//        let mail = Mail(from: from, to: [to], subject: subject, text: text)
//
//        smtp.send(mail) { (err) in
//            XCTAssertNil(err)
//            self.x?.fulfill()
//        }
//        
//        waitForExpectations(timeout: 5) { (_) in }
//    }
    
    // NOTE: Some servers like Gmail support IPv6, and if your network does not,
    //       you will first attempt to connect via IPv6, then timeout, and fall
    //       back to IPv4. You can avoid this by disabling IPv6.
    func testSendMailLogin() {
        x = expectation(description: "Send email through LOGIN auth.")
        getChainFilePath()
        
        let smtp = SMTP(hostname: gmailSMTP, user: gmailUser, password: password, authMethods: [.login], chainFilePath: chainFilePath, chainFilePassword: chainFilePassword, selfSignedCerts: selfSignedCerts)
        let from = User(name: self.from, email: gmailUser)
        let to = User(name: self.to, email: gmailUser)
        let mail = Mail(from: from, to: [to], subject: subject, text: text)
        
        smtp.send(mail) { (err) in
            XCTAssertNil(err)
            self.x?.fulfill()
        }
        
        waitForExpectations(timeout: 5) { (_) in }
    }

    func testSendMailPlain()  {
        x = expectation(description: "Send email through PLAIN auth.")
        getChainFilePath()
        
        let smtp = SMTP(hostname: gmailSMTP, user: gmailUser, password: password, authMethods: [.plain], chainFilePath: chainFilePath, chainFilePassword: chainFilePassword, selfSignedCerts: selfSignedCerts)
        let from = User(name: self.from, email: gmailUser)
        let to = User(name: self.to, email: gmailUser)
        let mail = Mail(from: from, to: [to], subject: subject, text: text)
        
        smtp.send(mail) { (err) in
            XCTAssertNil(err)
            self.x?.fulfill()
        }
        
        waitForExpectations(timeout: 5) { (_) in }
    }

    // Sending mails through XOAUTH2 has been tested and passed. This test is 
    // here in liue of having a fresh access token.
    func testXOAuth2Encoding() {
        let user = "foo@bar.com"
        let token = "token"
        
        // echo -ne "user=foo@bar.com\001auth=Bearer token\001\001"|base64
        let expected = "dXNlcj1mb29AYmFyLmNvbQFhdXRoPUJlYXJlciB0b2tlbgEB"
        let result = AuthCredentials.xoauth2(user: user, accessToken: token)
        XCTAssertEqual(result, expected)
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
