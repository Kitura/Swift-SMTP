/**
 * Copyright IBM Corporation 2018
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

class TestTLSMode: XCTestCase {
    static var allTests = [
        ("testNormal", testNormal),
        ("testIgnoreTLS", testIgnoreTLS),
        ("testRequireTLS", testRequireTLS),
        ("testRequireSTARTTLS", testRequireSTARTTLS)
    ]

    func testNormal() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: testDuration) }

        do {
            _ = try SMTPSocket(
                hostname: hostname,
                email: email,
                password: password,
                port: port,
                tlsMode: .normal,
                tlsConfiguration: nil,
                authMethods: authMethods,
                domainName: domainName,
                timeout: timeout
            )
            expectation.fulfill()
        } catch {
            XCTFail(String(describing: error))
            expectation.fulfill()
        }
    }

    func testIgnoreTLS() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: testDuration) }

        do {
            _ = try SMTPSocket(
                hostname: hostname,
                email: email,
                password: password,
                port: port,
                tlsMode: .ignoreTLS,
                tlsConfiguration: nil,
                authMethods: authMethods,
                domainName: domainName,
                timeout: timeout
            )
            XCTFail()
            expectation.fulfill()
        } catch {
            if case SMTPError.noAuthMethodsOrRequiresTLS = error {
                expectation.fulfill()
            } else {
                XCTFail(String(describing: error))
                expectation.fulfill()
            }
        }
    }

    func testRequireTLS() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: testDuration) }

        do {
            _ = try SMTPSocket(
                hostname: hostname,
                email: email,
                password: password,
                port: 465,
                tlsMode: .requireTLS,
                tlsConfiguration: nil,
                authMethods: authMethods,
                domainName: domainName,
                timeout: timeout
            )
            expectation.fulfill()
        } catch {
            XCTFail(String(describing: error))
            expectation.fulfill()
        }
    }

    func testRequireSTARTTLS() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: testDuration) }

        do {
            _ = try SMTPSocket(
                hostname: hostname,
                email: email,
                password: password,
                port: port,
                tlsMode: .requireSTARTTLS,
                tlsConfiguration: nil,
                authMethods: authMethods,
                domainName: domainName,
                timeout: timeout
            )
            expectation.fulfill()
        } catch {
            XCTFail(String(describing: error))
            expectation.fulfill()
        }
    }
}
