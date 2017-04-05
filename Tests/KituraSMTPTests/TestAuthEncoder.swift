/**
 * Copyright IBM Corporation 2017
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

import Foundation

import XCTest
@testable import KituraSMTP

class TestAuthEncoder: XCTestCase {
    static var allTests : [(String, (TestAuthEncoder) -> () throws -> Void)] {
        return [
            ("testCramMD5", testCramMD5),
            ("testLogin", testLogin),
            ("testPlain", testPlain),
            ("testXOAuth2", testXOAuth2),
            ("testLinuxTestSuiteIncludesAllTests", testLinuxTestSuiteIncludesAllTests)
        ]
    }
    
    func testCramMD5() throws {
        let user = "foo@bar.com"
        let password = "password"
        let challenge = "aGVsbG8="
        
        // http://busylog.net/cram-md5-online-generator/
        let expected = "Zm9vQGJhci5jb20gMjhmOGNhMDI0YjBlNjE4YWUzNWQ0NmRiODExNzU2NjM="
        let result = try AuthEncoder.cramMD5(challenge: challenge, user: user, password: password)
        XCTAssertEqual(result, expected)
    }
    
    func testLogin() {
        let user = "foo@bar.com"
        let password = "password"
        
        let expected = ("Zm9vQGJhci5jb20=", "cGFzc3dvcmQ=")
        let result = AuthEncoder.login(user: user, password: password)
        XCTAssertEqual(result.encodedUser, expected.0)
        XCTAssertEqual(result.encodedPassword, expected.1)
    }
    
    func testPlain() {
        let user = "test"
        let password = "testpass"
        
        // echo -ne "\0foo@bar.com\0password"|base64
        let expected = "AHRlc3QAdGVzdHBhc3M="
        let result = AuthEncoder.plain(user: user, password: password)
        XCTAssertEqual(result, expected)
    }
    
    func testXOAuth2() {
        let user = "foo@bar.com"
        let token = "token"
        
        // echo -ne "user=foo@bar.com\001auth=Bearer token\001\001"|base64
        let expected = "dXNlcj1mb29AYmFyLmNvbQFhdXRoPUJlYXJlciB0b2tlbgEB"
        let result = AuthEncoder.xoauth2(user: user, accessToken: token)
        XCTAssertEqual(result, expected)
    }
    
    func testLinuxTestSuiteIncludesAllTests() {
        #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
            let thisClass = type(of: self)
            let linuxCount = thisClass.allTests.count
            let darwinCount = Int(thisClass.defaultTestSuite().testCaseCount)
            XCTAssertEqual(linuxCount, darwinCount, "\(darwinCount - linuxCount) tests are missing from allTests")
        #endif
    }
}
