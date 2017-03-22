import XCTest
@testable import KituraSMTP

/**
 NOTE:
 Some servers like Gmail support IPv6, and if your network does not, you
 will first attempt to connect via IPv6, then timeout, and fall back to
 IPv4. You can avoid this by disabling IPv6.
 */

class TestLogin: XCTestCase {
    static var allTests : [(String, (TestLogin) -> () throws -> Void)] {
        return [
            ("testLoginCramMD5", testLoginCramMD5),
            ("testLoginLogin", testLoginLogin),
            ("testLoginPlain", testLoginPlain),
        ]
    }
    
    func testLoginCramMD5() throws {
        let smtp = SMTP(hostname: junoSMTP, user: junoUser, password: password, authMethods: [.cramMD5])
        _ = try SMTPLogin(hostname: smtp.hostname, user: smtp.user, password: smtp.password, accessToken: smtp.accessToken, domainName: smtp.domainName, authMethods: smtp.authMethods, chainFilePath: smtp.chainFilePath, chainFilePassword: smtp.chainFilePassword, selfSignedCerts: smtp.selfSignedCerts).login()
    }
    
    func testLoginLogin() throws {
        let smtp = SMTP(hostname: gmailSMTP, user: gmailUser, password: password, authMethods: [.login], chainFilePath: chainFilePath, chainFilePassword: chainFilePassword, selfSignedCerts: selfSignedCerts)
        _ = try SMTPLogin(hostname: smtp.hostname, user: smtp.user, password: smtp.password, accessToken: smtp.accessToken, domainName: smtp.domainName, authMethods: smtp.authMethods, chainFilePath: smtp.chainFilePath, chainFilePassword: smtp.chainFilePassword, selfSignedCerts: smtp.selfSignedCerts).login()
    }
    
    func testLoginPlain() throws {
        let smtp = SMTP(hostname: gmailSMTP, user: gmailUser, password: password, authMethods: [.plain], chainFilePath: chainFilePath, chainFilePassword: chainFilePassword, selfSignedCerts: selfSignedCerts)
        _ = try SMTPLogin(hostname: smtp.hostname, user: smtp.user, password: smtp.password, accessToken: smtp.accessToken, domainName: smtp.domainName, authMethods: smtp.authMethods, chainFilePath: smtp.chainFilePath, chainFilePassword: smtp.chainFilePassword, selfSignedCerts: smtp.selfSignedCerts).login()
    }
}
