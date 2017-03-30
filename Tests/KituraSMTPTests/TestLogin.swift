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

import XCTest
@testable import KituraSMTP

class TestLogin: XCTestCase {
    static var allTests : [(String, (TestLogin) -> () throws -> Void)] {
        return [
            ("testLogin", testLogin),
            ("testPlain", testPlain),
            ("testSecure", testSecure),
            ("testBadCredentials", testBadCredentials),
            ("testPort0", testPort0),
            ("testBadPort", testBadPort)
        ]
    }
    
    func testLogin() throws {
        SMTPLogin(hostname: smtp.hostname, user: smtp.user, password: smtp.password, port: smtp.port, secure: smtp.secure, authMethods: [.login], domainName: smtp.domainName, accessToken: smtp.accessToken, timeout: smtp.timeout) { (_, err) in
            XCTAssertNil(err)
            self.x.fulfill()
            }.login()
        waitForExpectations(timeout: timeout)
    }
    
    func testPlain() throws {
        SMTPLogin(hostname: smtp.hostname, user: smtp.user, password: smtp.password, port: smtp.port, secure: smtp.secure, authMethods: [.plain], domainName: smtp.domainName, accessToken: smtp.accessToken, timeout: smtp.timeout) { (_, err) in
            XCTAssertNil(err)
            self.x.fulfill()
            }.login()
        waitForExpectations(timeout: timeout)
    }
    
    func testSecure() throws {
        SMTPLogin(hostname: smtp.hostname, user: smtp.user, password: smtp.password, port: smtp.port, secure: smtp.secure, authMethods: [.plain], domainName: smtp.domainName, accessToken: smtp.accessToken, timeout: smtp.timeout) { (_, err) in
            XCTAssertNil(err)
            self.x.fulfill()
            }.login()
        waitForExpectations(timeout: timeout)
    }
    
    func testBadCredentials() throws {
        SMTPLogin(hostname: smtp.hostname, user: smtp.user, password: "", port: smtp.port, secure: smtp.secure, authMethods: smtp.authMethods, domainName: smtp.domainName, accessToken: smtp.accessToken, timeout: smtp.timeout) { (_, err) in
            if let err = err as? SMTPError, case .badResponse = err {
                self.x.fulfill()
            } else {
                XCTFail()
            }
            }.login()
        waitForExpectations(timeout: timeout)
    }
    
    func testPort0() throws {
        SMTPLogin(hostname: smtp.hostname, user: smtp.user, password: smtp.password, port: 0, secure: smtp.secure, authMethods: smtp.authMethods, domainName: smtp.domainName, accessToken: smtp.accessToken, timeout: smtp.timeout) { (_, err) in
            XCTAssertNotNil(err)
            self.x.fulfill()
            }.login()
        waitForExpectations(timeout: timeout)
    }
    
    func testBadPort() throws {
        SMTPLogin(hostname: smtp.hostname, user: smtp.user, password: smtp.password, port: 1, secure: smtp.secure, authMethods: smtp.authMethods, domainName: smtp.domainName, accessToken: smtp.accessToken, timeout: smtp.timeout) { (_, err) in
            XCTAssertNotNil(err)
            self.x.fulfill()
            }.login()
        waitForExpectations(timeout: timeout)
    }
    
    var x: XCTestExpectation!
    override func setUp() { x = expectation(description: "") }
}
