import XCTest
@testable import KituraSMTP

class KituraSMTPTests: XCTestCase {
    static var allTests : [(String, (KituraSMTPTests) -> () throws -> Void)] {
        return [
        ]
    }

    let from = "Dr. Light"
    let to = "Megaman"
    let subject = "Dr. Wily must be stopped"
    let text = "Humans and robots living together in harmony and equality. That was my ultimate wish."

    let junoSMTP = "smtp.juno.com"
    let junoUser = "kiturasmtp@juno.com"
    let junoPassword = "ibm123"
    
    let gmailSMTP = "smtp.gmail.com"
    let gmailUser = "kiturasmtp@gmail.com"
    let gmailPassword = "ibm12345"
    
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
    
    func testSendMailCramMD5() throws {
        let smtp = try SMTP(url: junoSMTP, user: junoUser, password: junoPassword, authMethods: [.cramMD5])
        let from = try User(name: self.from, email: junoUser)
        let to = try User(name: self.to, email: junoUser)
        let mail = Mail(from: from, to: to, subject: subject, text: text)
        try smtp.send(mail)
    }
    
    func testSendMailLogin() throws {
        getChainFilePath()
        let smtp = try SMTP(url: gmailSMTP, user: gmailUser, password: gmailPassword, authMethods: [.login], chainFilePath: chainFilePath, chainFilePassword: chainFilePassword, selfSignedCerts: selfSignedCerts)
        let from = try User(name: self.from, email: gmailUser)
        let to = try User(name: self.to, email: gmailUser)
        let mail = Mail(from: from, to: to, subject: subject, text: text)
        try smtp.send(mail)
    }

    func testSendMailPlain() throws {
        getChainFilePath()
        let smtp = try SMTP(url: gmailSMTP, user: gmailUser, password: gmailPassword, authMethods: [.plain], chainFilePath: chainFilePath, chainFilePassword: chainFilePassword, selfSignedCerts: selfSignedCerts)
        let from = try User(name: self.from, email: gmailUser)
        let to = try User(name: self.to, email: gmailUser)
        let mail = Mail(from: from, to: to, subject: subject, text: text)
        try smtp.send(mail)
    }
    
    // Sending mails through XOAUTH2 has been tested and passed. This test is here in liue of having a fresh access token.
    func testXOAuth2Encoding() {
        let user = "foo@bar.com"
        let token = "token"
        
        // echo -ne "user=foo@bar.com\001auth=Bearer token\001\001"|base64
        let expected = "dXNlcj1mb29AYmFyLmNvbQFhdXRoPUJlYXJlciB0b2tlbgEB"
        let result = AuthCredentials.xoauth2(user: user, accessToken: token)
        XCTAssertEqual(result, expected)
    }
}
