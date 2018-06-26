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

class TestSMTPSocket: XCTestCase {
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

        do {
            _ = try SMTPSocket(
                hostname: hostname,
                email: email,
                password: "bad password",
                port: port,
                useTLS: useTLS,
                tlsConfiguration: nil,
                authMethods: authMethods,
                domainName: domainName,
                timeout: timeout
            )
            XCTFail()
            x.fulfill()
        } catch {
            if case SMTPError.badResponse = error {
                x.fulfill()
            } else {
                XCTFail(String(describing: error))
                x.fulfill()
            }
        }
    }

    func testBadPort() throws {
        let x = expectation(description: #function)
        defer { waitForExpectations(timeout: testDuration) }

        do {
            _ = try SMTPSocket(
                hostname: hostname,
                email: email,
                password: password,
                port: 1,
                useTLS: useTLS,
                tlsConfiguration: nil,
                authMethods: authMethods,
                domainName: domainName,
                timeout: 5
            )
            XCTFail()
            x.fulfill()
        } catch {
            x.fulfill()
        }
    }

    func testLogin() throws {
        let x = expectation(description: #function)
        defer { waitForExpectations(timeout: testDuration) }

        do {
            _ = try SMTPSocket(
                hostname: hostname,
                email: email,
                password: password,
                port: port,
                useTLS: useTLS,
                tlsConfiguration: nil,
                authMethods: [AuthMethod.login.rawValue: .login],
                domainName: domainName,
                timeout: timeout
            )
            x.fulfill()
        } catch {
            XCTFail(String(describing: error))
            x.fulfill()
        }
    }

    func testPlain() throws {
        let x = expectation(description: #function)
        defer { waitForExpectations(timeout: testDuration) }

        do {
            _ = try SMTPSocket(
                hostname: hostname,
                email: email,
                password: password,
                port: port,
                useTLS: useTLS,
                tlsConfiguration: nil,
                authMethods: [AuthMethod.plain.rawValue: .plain],
                domainName: domainName,
                timeout: timeout
            )
            x.fulfill()
        } catch {
            XCTFail(String(describing: error))
            x.fulfill()
        }
    }

    func testPort0() throws {
        let x = expectation(description: #function)
        defer { waitForExpectations(timeout: testDuration) }

        do {
            _ = try SMTPSocket(
                hostname: hostname,
                email: email,
                password: password,
                port: 0,
                useTLS: useTLS,
                tlsConfiguration: nil,
                authMethods: authMethods,
                domainName: domainName,
                timeout: timeout
            )
            XCTFail()
            x.fulfill()
        } catch {
            x.fulfill()
        }
    }

    func testSSL() throws {
        let x = self.expectation(description: #function)
        defer { waitForExpectations(timeout: testDuration) }

        do {
            _ = try SMTPSocket(
                hostname: hostname,
                email: email,
                password: password,
                port: port,
                useTLS: useTLS,
                tlsConfiguration: tlsConfiguration,
                authMethods: authMethods,
                domainName: domainName,
                timeout: timeout
            )
            x.fulfill()
        } catch {
            XCTFail(String(describing: error))
            x.fulfill()
        }
    }
}
