import XCTest
@testable import KituraSMTP

class KituraSMTPTests: XCTestCase {
    static var allTests : [(String, (KituraSMTPTests) -> () throws -> Void)] {
        return [
        ]
    }

    let from = "Dr. Light"
    let to = "Megaman"
    let subject = "Humans and robots living together in harmony and equality."
    let text = "That was my ultimate wish."

    let junoSMTP = "smtp.juno.com"
    let junoUser = "kitura-smtp@juno.com"
    
    let gmailSMTP = "smtp.gmail.com"
    let gmailUser = "kiturasmtp@gmail.com"
    
    let password = "ibm12345"
    
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
//    func testSendMailCramMD5() throws {
//        x = expectation(description: "Send email through CRAM-MD5 auth.")
//
//        let smtp = try SMTP(hostname: junoSMTP, user: junoUser, password: password, authMethods: [.cramMD5])
//        let from = try User(name: self.from, email: junoUser)
//        let to = try User(name: self.to, email: junoUser)
//        let mail = Mail(from: from, to: to, subject: subject, text: text)
//
//        smtp.send(mail) { (err) in
//            XCTAssertNil(err)
//            
//            self.x?.fulfill()
//        }
//        
//        waitForExpectations(timeout: 5) { (_) in }
//    }
    
    // NOTE: Some servers like Gmail support IPv6, and if your network does not,
    //       you will first attempt to connect via IPv6, then timeout, and fall
    //       back to IPv4. You can avoid this by disabling IPv6.
    func testSendMailLogin() throws {
        x = expectation(description: "Send email through LOGIN auth.")
        getChainFilePath()
        
        let smtp = try SMTP(hostname: gmailSMTP, user: gmailUser, password: password, authMethods: [.login], chainFilePath: chainFilePath, chainFilePassword: chainFilePassword, selfSignedCerts: selfSignedCerts)
        let from = try User(name: self.from, email: gmailUser)
        let to = try User(name: self.to, email: gmailUser)
        let mail = Mail(from: from, to: to, subject: subject, text: text)
        
        smtp.send(mail) { (err) in
            XCTAssertNil(err)
            
            self.x?.fulfill()
        }
        
        waitForExpectations(timeout: 5) { (_) in }
    }

    func testSendMailPlain() throws {
        x = expectation(description: "Send email through PLAIN auth.")
        getChainFilePath()
        
        let smtp = try SMTP(hostname: gmailSMTP, user: gmailUser, password: password, authMethods: [.plain], chainFilePath: chainFilePath, chainFilePassword: chainFilePassword, selfSignedCerts: selfSignedCerts)
        let from = try User(name: self.from, email: gmailUser)
        let to = try User(name: self.to, email: gmailUser)
        let mail = Mail(from: from, to: to, subject: subject, text: text)
        
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
}
