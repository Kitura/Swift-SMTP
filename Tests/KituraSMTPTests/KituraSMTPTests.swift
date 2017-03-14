import XCTest
@testable import KituraSMTP

class KituraSMTPTests: XCTestCase {
    static var allTests : [(String, (KituraSMTPTests) -> () throws -> Void)] {
        return [
        ]
    }
    
    func test_1() throws {
        let smtp = try SMTP(url: "smtp.gmx.com", user: "kitura@gmx.us", password: "Passw0rd", chainFilePath: "/Users/quanvo/temp/cert.pfx", chainFilePassword: "kitura")
        let from = try User(email: "kitura@gmx.us")
        let to = try User(email: "kitura@gmx.us")
        let mail = Mail(from: from, to: to, subject: "Hey whassup hello", text: "you my trap queen")

        try smtp.send(mail)
    }
    
    func testCramMD5Encoding() {
        let user = "foo@bar.com"
        let password = "password"
        let challenge = "aGVsbG8="
        
        // Calculated by http://busylog.net/cram-md5-online-generator/
        let expected = "Zm9vQGJhci5jb20gMjhmOGNhMDI0YjBlNjE4YWUzNWQ0NmRiODExNzU2NjM="
        
        do {
            let result = try AuthCredentials.cramMD5(challenge: challenge, user: user, password: password)
            XCTAssertEqual(result, expected)
        } catch {
            XCTFail("Should be no error.")
        }
    }

}
