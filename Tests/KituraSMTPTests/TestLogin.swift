//
//  TestLogin.swift
//  KituraSMTP
//
//  Created by Quan Vo on 3/20/17.
//
//

import XCTest
@testable import KituraSMTP

class TestLogin: XCTestCase {
    static var allTests : [(String, (TestLogin) -> () throws -> Void)] {
        return [
            ("testLoginCramMD5", testLoginCramMD5),
            ("testLoginLogin", testLoginLogin),
            ("testLoginPlain", testLoginPlain),
        ]
    }
    
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
        if pathToTests.hasSuffix("TestLogin.swift") {
            pathToTests = pathToTests.replacingOccurrences(of: "TestLogin.swift", with: "")
        }
        chainFilePath = URL(fileURLWithPath: "\(pathToTests)\("cert.pfx")").path
    }
    
    func testLoginCramMD5() throws {
        let smtp = SMTP(hostname: junoSMTP, user: junoUser, password: password, authMethods: [.cramMD5])
        _ = try SMTPLogin(config: smtp.config, socket: try SMTPSocket()).login()
    }
    
    // NOTE: Some servers like Gmail support IPv6, and if your network does not,
    //       you will first attempt to connect via IPv6, then timeout, and fall
    //       back to IPv4. You can avoid this by disabling IPv6.
    func testLoginLogin() throws {
        getChainFilePath()
        let smtp = SMTP(hostname: gmailSMTP, user: gmailUser, password: password, authMethods: [.login], chainFilePath: chainFilePath, chainFilePassword: chainFilePassword, selfSignedCerts: selfSignedCerts)
        _ = try SMTPLogin(config: smtp.config, socket: try SMTPSocket()).login()
    }
    
    func testLoginPlain() throws {
        getChainFilePath()
        let smtp = SMTP(hostname: gmailSMTP, user: gmailUser, password: password, authMethods: [.plain], chainFilePath: chainFilePath, chainFilePassword: chainFilePassword, selfSignedCerts: selfSignedCerts)
        _ = try SMTPLogin(config: smtp.config, socket: try SMTPSocket()).login()
    }
}
