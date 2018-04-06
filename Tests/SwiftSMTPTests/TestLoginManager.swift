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
@testable import SwiftSMTP

class TestLoginManager: XCTestCase {
    static var allTests = [
        ("testBadCredentials", testBadCredentials),
        ("testBadPort", testBadPort),
        ("testLogin", testLogin),
        ("testPlain", testPlain),
        ("testPort0", testPort0),
        ("testSSL", testSSL)
    ]

    func testBadCredentials() throws {
        let x = expectation(description: #function)
        defer { waitForExpectations(timeout: testDuration) }

        LoginManager(
            hostname: hostname,
            email: email,
            password: "bad password",
            port: port,
            useTLS: useTLS,
            tlsConfiguration: nil,
            authMethods: authMethods,
            accessToken: accessToken,
            domainName: domainName,
            timeout: timeout).login { result in
                switch result {
                case .failure(let error):
                    if case SMTPError.badResponse = error {
                        x.fulfill()
                    } else {
                        XCTFail()
                        x.fulfill()
                    }
                case .success:
                    XCTFail()
                    x.fulfill()
                }
        }
    }

    func testBadPort() throws {
        let x = expectation(description: #function)
        defer { waitForExpectations(timeout: testDuration) }

        LoginManager(
            hostname: hostname,
            email: email,
            password: password,
            port: 1,
            useTLS: useTLS,
            tlsConfiguration: nil,
            authMethods: authMethods,
            accessToken: accessToken,
            domainName: domainName,
            timeout: 5).login { result in
                switch result {
                case .failure:
                    x.fulfill()
                case .success:
                    XCTFail()
                    x.fulfill()
                }
        }
    }

    func testLogin() throws {
        let x = expectation(description: #function)
        defer { waitForExpectations(timeout: testDuration) }

        LoginManager(
            hostname: hostname,
            email: email,
            password: password,
            port: port,
            useTLS: useTLS,
            tlsConfiguration: nil,
            authMethods: [.login],
            accessToken: accessToken,
            domainName: domainName,
            timeout: timeout).login { result in
                switch result {
                case .failure:
                    XCTFail()
                    x.fulfill()
                case .success:
                    x.fulfill()
                }
        }
    }

    func testPlain() throws {
        let x = expectation(description: #function)
        defer { waitForExpectations(timeout: testDuration) }

        LoginManager(
            hostname: hostname,
            email: email,
            password: password,
            port: port,
            useTLS: useTLS,
            tlsConfiguration: nil,
            authMethods: [.plain],
            accessToken: accessToken,
            domainName: domainName,
            timeout: timeout).login { result in
                switch result {
                case .failure:
                    XCTFail()
                    x.fulfill()
                case .success:
                    x.fulfill()
                }
        }
    }

    func testPort0() throws {
        let x = expectation(description: #function)
        defer { waitForExpectations(timeout: testDuration) }

        LoginManager(
            hostname: hostname,
            email: email,
            password: password,
            port: 0,
            useTLS: useTLS,
            tlsConfiguration: nil,
            authMethods: [.plain],
            accessToken: accessToken,
            domainName: domainName,
            timeout: 5).login { result in
                switch result {
                case .failure:
                    x.fulfill()
                case .success:
                    XCTFail()
                    x.fulfill()
                }
        }
    }

    func testSSL() throws {
        let x = self.expectation(description: #function)
        defer { waitForExpectations(timeout: testDuration) }

        LoginManager(
            hostname: hostname,
            email: email,
            password: password,
            port: port,
            useTLS: useTLS,
            tlsConfiguration: tlsConfiguration,
            authMethods: authMethods,
            accessToken: accessToken,
            domainName: domainName,
            timeout: timeout).login { result in
                switch result {
                case .failure:
                    XCTFail()
                    x.fulfill()
                case .success:
                    x.fulfill()
                }
        }
    }
}
