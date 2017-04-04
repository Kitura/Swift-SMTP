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
            ("testBadCredentials", testBadCredentials),
            ("testPort0", testPort0),
            ("testBadPort", testBadPort)
        ]
    }
    
    func testLogin() throws {
        Login(hostname: hostname, user: user, password: password, port: port, ssl: ssl, authMethods: [.login], domainName: domainName, accessToken: nil, timeout: timeout) { (_, err) in
            XCTAssertNil(err)
            self.x.fulfill()
        }.login()
        waitForExpectations(timeout: testDuration)
    }
    
    func testPlain() throws {
        Login(hostname: hostname, user: user, password: password, port: port, ssl: ssl, authMethods: [.plain], domainName: domainName, accessToken: nil, timeout: timeout) { (_, err) in
            XCTAssertNil(err)
            self.x.fulfill()
            }.login()
        waitForExpectations(timeout: testDuration)
    }
    
    func testBadCredentials() throws {
        Login(hostname: hostname, user: user, password: "", port: port, ssl: ssl, authMethods: authMethods, domainName: domainName, accessToken: nil, timeout: timeout) { (_, err) in
            if let err = err as? SMTPError, case .badResponse = err {
                self.x.fulfill()
            } else {
                XCTFail()
            }
            }.login()
        waitForExpectations(timeout: testDuration)
    }
    
    func testPort0() throws {
        Login(hostname: hostname, user: user, password: password, port: 0, ssl: ssl, authMethods: authMethods, domainName: domainName, accessToken: nil, timeout: timeout) { (_, err) in
            XCTAssertNotNil(err)
            self.x.fulfill()
            }.login()
        waitForExpectations(timeout: testDuration)
    }
    
    func testBadPort() throws {
        Login(hostname: hostname, user: user, password: password, port: 1, ssl: ssl, authMethods: authMethods, domainName: domainName, accessToken: nil, timeout: timeout) { (_, err) in
            if let err = err as? SMTPError, case .couldNotConnectToServer(_, _) = err {
                self.x.fulfill()
            } else {
                XCTFail()
            }
            }.login()
        waitForExpectations(timeout: testDuration)
    }
    
    var x: XCTestExpectation!
    override func setUp() { x = expectation(description: "") }
}
