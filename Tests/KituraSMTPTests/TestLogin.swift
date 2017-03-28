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

#if os(Linux)
    import Glibc
#endif

class TestLogin: XCTestCase {
    static var allTests : [(String, (TestLogin) -> () throws -> Void)] {
        return [
//            ("testCramMD5", testCramMD5),
            ("testLogin", testLogin),
            ("testPlain", testPlain),
            ("testPortSSL", testPortSSL),
            ("testPortTLS", testPortTLS),
            ("testPort0", testPort0),
            ("testBadPort", testBadPort),
            ("testRandomPort", testRandomPort)
        ]
    }
    
//    func testCramMD5() throws {
//        _ = try SMTPLogin(hostname: junoSMTP, user: junoUser, password: smtp.password, port: Proto.tls.rawValue, authMethods: [.cramMD5], domainName: smtp.domainName, accessToken: smtp.accessToken).login()
//    }
    
    func testLogin() throws {
        _ = try SMTPLogin(hostname: smtp.hostname, user: smtp.user, password: smtp.password, port: Proto.tls.rawValue, authMethods: [.login], domainName: smtp.domainName, accessToken: smtp.accessToken).login()
    }
    
    func testPlain() throws {
        _ = try SMTPLogin(hostname: smtp.hostname, user: smtp.user, password: smtp.password, port: Proto.tls.rawValue, authMethods: [.plain], domainName: smtp.domainName, accessToken: smtp.accessToken).login()
    }
    
    func testPortSSL() throws {
        _ = try SMTPLogin(hostname: smtp.hostname, user: smtp.user, password: smtp.password, port: Proto.ssl.rawValue, authMethods: smtp.authMethods, domainName: smtp.domainName, accessToken: smtp.accessToken).login()
    }
    
    func testPortTLS() throws {
        _ = try SMTPLogin(hostname: smtp.hostname, user: smtp.user, password: smtp.password, port: Proto.tls.rawValue, authMethods: smtp.authMethods, domainName: smtp.domainName, accessToken: smtp.accessToken).login()
    }
    
    func testPort0() throws {
        _ = try SMTPLogin(hostname: smtp.hostname, user: smtp.user, password: smtp.password, port: 0, authMethods: smtp.authMethods, domainName: smtp.domainName, accessToken: smtp.accessToken).login()
    }
    
    func testBadPort() throws {
        _ = try SMTPLogin(hostname: smtp.hostname, user: smtp.user, password: smtp.password, port: 1, authMethods: smtp.authMethods, domainName: smtp.domainName, accessToken: smtp.accessToken).login()
    }
    
    func testRandomPort() throws {
        let maxPort = 65535
        
        #if os(Linux)
            srand(UInt32(time(nil)))
            let randomPort = Int32(random() % maxPort) + 1
        #else
            let randomPort = Int32(arc4random_uniform(UInt32(maxPort)) + 1)
        #endif
        
        _ = try SMTPLogin(hostname: smtp.hostname, user: smtp.user, password: smtp.password, port: randomPort, authMethods: smtp.authMethods, domainName: smtp.domainName, accessToken: smtp.accessToken).login()
    }
}
