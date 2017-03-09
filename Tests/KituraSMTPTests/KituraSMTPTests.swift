import XCTest
import KituraSMTP

class KituraSMTPTests: XCTestCase {
    static var allTests : [(String, (KituraSMTPTests) -> () throws -> Void)] {
        return [
        ]
    }
    
    func test_1() throws {
        let smtp = try SMTP(url: "smtp.gmx.com", port: 587, username: "kitura@gmx.us", password: "Passw0rd")
        let from = try User(email: "kitura@gmx.us")
        let to = try User(email: "kitura@gmx.us")
        let mail = Mail(from: from, to: to, subject: "Hey whassup hello", text: "you my trap queen")

        try smtp.send(mail)
    }
}
