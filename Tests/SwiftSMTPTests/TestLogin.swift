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

class TestLogin: XCTestCase {
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

        try Login(hostname: hostname,
                  email: email,
                  password: "bad password",
                  port: port,
                  ssl: nil,
                  authMethods: authMethods,
                  domainName: domainName,
                  accessToken: nil,
                  timeout: timeout) { (loginResult) in
                    switch loginResult {
                    case .failure(let error):
                        if let error = error as? SMTPError, case .badResponse = error {
                            x.fulfill()
                        } else {
                            XCTFail()
                        }
                    case .success(_): XCTFail()
                    }
            }.login()
    }

    func testBadPort() throws {
        let x = expectation(description: #function)
        defer { waitForExpectations(timeout: testDuration) }

        try Login(hostname: hostname,
                  email: email,
                  password: password,
                  port: 1,
                  ssl: nil,
                  authMethods: authMethods,
                  domainName: domainName,
                  accessToken: nil,
                  timeout: 5) { (loginResult) in
                    switch loginResult {
                    case .failure(_): x.fulfill()
                    case .success(_): XCTFail()
                    }
            }.login()
    }

    func testLogin() throws {
        let x = expectation(description: #function)
        defer { waitForExpectations(timeout: testDuration) }

        try Login(hostname: hostname,
                  email: email,
                  password: password,
                  port: port,
                  ssl: nil,
                  authMethods: [.login],
                  domainName: domainName,
                  accessToken: nil,
                  timeout: timeout) { (loginResult) in
                    switch loginResult {
                    case .failure(_): XCTFail()
                    case .success(_): x.fulfill()
                    }
            }.login()
    }

    func testPlain() throws {
        let x = expectation(description: #function)
        defer { waitForExpectations(timeout: testDuration) }

        try Login(hostname: hostname,
                  email: email,
                  password: password,
                  port: port,
                  ssl: nil,
                  authMethods: [.plain],
                  domainName: domainName,
                  accessToken: nil,
                  timeout: timeout) { (loginResult) in
                    switch loginResult {
                    case .failure(_): XCTFail()
                    case .success(_): x.fulfill()
                    }
            }.login()
    }

    func testPort0() throws {
        let x = expectation(description: #function)
        defer { waitForExpectations(timeout: testDuration) }

        try Login(hostname: hostname,
                  email: email,
                  password: password,
                  port: 0,
                  ssl: nil,
                  authMethods: authMethods,
                  domainName: domainName,
                  accessToken: nil,
                  timeout: 5) { (loginResult) in
                    switch loginResult {
                    case .failure(_): x.fulfill()
                    case .success(_): XCTFail()
                    }
            }.login()
    }

    func testSSL() throws {
        let x = self.expectation(description: #function)
        defer { waitForExpectations(timeout: testDuration) }

        try Login(hostname: hostname,
                  email: email,
                  password: password,
                  port: port,
                  ssl: ssl,
                  authMethods: authMethods,
                  domainName: domainName,
                  accessToken: nil,
                  timeout: timeout) { (loginResult) in
                    switch loginResult {
                    case .failure(_): XCTFail()
                    case .success(_): x.fulfill()
                    }
            }.login()
    }
}
