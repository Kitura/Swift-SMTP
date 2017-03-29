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
            ("testCramMD5", testCramMD5),
            ("testLogin", testLogin),
            ("testPlain", testPlain),
            ("testSecure", testSecure),
            ("testPortSSL", testPortSSL),
            ("testPortTLS", testPortTLS),
            ("testPort0", testPort0),
            ("testBadPort", testBadPort),
            ("testRandomPort", testRandomPort)
        ]
    }
    
    func testCramMD5() throws {
        SMTPLogin(hostname: smtp.hostname, user: smtp.user, password: smtp.password, port: smtp.port, secure: smtp.secure, authMethods: [.cramMD5], domainName: smtp.domainName, accessToken: smtp.accessToken).login(callback: { (_) in
            self.x.fulfill()
        })
        waitForExpectations(timeout: timeout)
    }
    
    func testLogin() throws {
        SMTPLogin(hostname: smtp.hostname, user: smtp.user, password: smtp.password, port: smtp.port, secure: smtp.secure, authMethods: [.login], domainName: smtp.domainName, accessToken: smtp.accessToken).login(callback: { (_) in
            self.x.fulfill()
        })
        waitForExpectations(timeout: timeout)
    }
    
    func testPlain() throws {
        SMTPLogin(hostname: gSMTP, user: gMail, password: gPassword, port: smtp.port, secure: gSecure, authMethods: [.plain], domainName: smtp.domainName, accessToken: smtp.accessToken).login(callback: { (_) in
            self.x.fulfill()
        })
        waitForExpectations(timeout: timeout)
    }
    
    func testSecure() throws {
        SMTPLogin(hostname: gSMTP, user: gMail, password: gPassword, port: smtp.port, secure: gSecure, authMethods: smtp.authMethods, domainName: smtp.domainName, accessToken: smtp.accessToken).login(callback: { (_) in
            self.x.fulfill()
        })
        waitForExpectations(timeout: timeout)
    }
    
    func testPortSSL() throws {
        SMTPLogin(hostname: smtp.hostname, user: smtp.user, password: smtp.password, port: Proto.ssl.rawValue, secure: smtp.secure, authMethods: smtp.authMethods, domainName: smtp.domainName, accessToken: smtp.accessToken).login(callback: { (_) in
            self.x.fulfill()
        })
        waitForExpectations(timeout: timeout)
    }
    
    func testPortTLS() throws {
        SMTPLogin(hostname: smtp.hostname, user: smtp.user, password: smtp.password, port: Proto.tls.rawValue, secure: smtp.secure, authMethods: smtp.authMethods, domainName: smtp.domainName, accessToken: smtp.accessToken).login(callback: { (_) in
            self.x.fulfill()
        })
        waitForExpectations(timeout: timeout)
    }
    
    func testPort0() throws {
        SMTPLogin(hostname: smtp.hostname, user: smtp.user, password: smtp.password, port: 0, secure: smtp.secure, authMethods: smtp.authMethods, domainName: smtp.domainName, accessToken: smtp.accessToken).login(callback: { (_) in
            self.x.fulfill()
        })
        waitForExpectations(timeout: timeout)
    }
    
    func testBadPort() throws {
        SMTPLogin(hostname: smtp.hostname, user: smtp.user, password: smtp.password, port: 1, secure: smtp.secure, authMethods: smtp.authMethods, domainName: smtp.domainName, accessToken: smtp.accessToken).login(callback: { (_) in
            self.x.fulfill()
        })
        waitForExpectations(timeout: timeout)
    }
    
    func testRandomPort() throws {
        let maxPort = 65535
        
        #if os(Linux)
            srand(UInt32(time(nil)))
            let randomPort = Int32(random() % maxPort) + 1
        #else
            let randomPort = Int32(arc4random_uniform(UInt32(maxPort)) + 1)
        #endif
        
        SMTPLogin(hostname: smtp.hostname, user: smtp.user, password: smtp.password, port: randomPort, secure: smtp.secure, authMethods: smtp.authMethods, domainName: smtp.domainName, accessToken: smtp.accessToken).login(callback: { (_) in
            self.x.fulfill()
        })
        
        waitForExpectations(timeout: timeout)
    }
    
    var x: XCTestExpectation!
    override func setUp() { x = expectation(description: "") }
}
