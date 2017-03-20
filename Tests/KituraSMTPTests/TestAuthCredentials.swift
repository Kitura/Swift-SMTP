//
//  AuthCredentials.swift
//  KituraSMTP
//
//  Created by Quan Vo on 3/20/17.
//
//

import XCTest
@testable import KituraSMTP

class TestAuthCredentials: XCTestCase {
    static var allTests : [(String, (TestAuthCredentials) -> () throws -> Void)] {
        return [
            ("testCramMD5", testCramMD5),
            ("testLogin", testLogin),
            ("testPlain", testPlain),
            ("testXOAuth2", testXOAuth2)
        ]
    }
    
    func testCramMD5() throws {
        let user = "foo@bar.com"
        let password = "password"
        let challenge = "aGVsbG8="
        
        // http://busylog.net/cram-md5-online-generator/
        let expected = "Zm9vQGJhci5jb20gMjhmOGNhMDI0YjBlNjE4YWUzNWQ0NmRiODExNzU2NjM="
        let result = try AuthCredentials.cramMD5(challenge: challenge, user: user, password: password)
        XCTAssertEqual(result, expected)
    }
    
    func testLogin() {
        let user = "foo@bar.com"
        let password = "password"
        
        let expected = ("Zm9vQGJhci5jb20=", "cGFzc3dvcmQ=")
        let result = AuthCredentials.login(user: user, password: password)
        XCTAssertEqual(result.encodedUser, expected.0)
        XCTAssertEqual(result.encodedPassword, expected.1)
    }
    
    func testPlain() {
        let user = "test"
        let password = "testpass"
        
        // echo -ne "\0foo@bar.com\0password"|base64
        let expected = "AHRlc3QAdGVzdHBhc3M="
        let result = AuthCredentials.plain(user: user, password: password)
        XCTAssertEqual(result, expected)
    }
    
    func testXOAuth2() {
        let user = "foo@bar.com"
        let token = "token"
        
        // echo -ne "user=foo@bar.com\001auth=Bearer token\001\001"|base64
        let expected = "dXNlcj1mb29AYmFyLmNvbQFhdXRoPUJlYXJlciB0b2tlbgEB"
        let result = AuthCredentials.xoauth2(user: user, accessToken: token)
        XCTAssertEqual(result, expected)
    }
}
