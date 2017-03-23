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
        _ = try SMTPLogin(hostname: smtp.hostname, user: smtp.user, password: smtp.password, port: Proto.tls.rawValue, accessToken: smtp.accessToken, domainName: smtp.domainName, authMethods: smtp.authMethods, chainFilePath: smtp.chainFilePath, chainFilePassword: smtp.chainFilePassword, selfSignedCerts: smtp.selfSignedCerts).login()
    }
    
    func testLoginLogin() throws {
        let smtp = SMTP(hostname: gmailSMTP, user: gmailUser, password: password, authMethods: [.login], chainFilePath: chainFilePath, chainFilePassword: chainFilePassword, selfSignedCerts: selfSignedCerts)
        _ = try SMTPLogin(hostname: smtp.hostname, user: smtp.user, password: smtp.password, port: Proto.tls.rawValue, accessToken: smtp.accessToken, domainName: smtp.domainName, authMethods: smtp.authMethods, chainFilePath: smtp.chainFilePath, chainFilePassword: smtp.chainFilePassword, selfSignedCerts: smtp.selfSignedCerts).login()
    }
    
    func testLoginPlain() throws {
        let smtp = SMTP(hostname: gmailSMTP, user: gmailUser, password: password, authMethods: [.plain], chainFilePath: chainFilePath, chainFilePassword: chainFilePassword, selfSignedCerts: selfSignedCerts)
        _ = try SMTPLogin(hostname: smtp.hostname, user: smtp.user, password: smtp.password, port: Proto.tls.rawValue, accessToken: smtp.accessToken, domainName: smtp.domainName, authMethods: smtp.authMethods, chainFilePath: smtp.chainFilePath, chainFilePassword: smtp.chainFilePassword, selfSignedCerts: smtp.selfSignedCerts).login()
    }
}
