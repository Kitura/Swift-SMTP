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
import KituraSMTP

class TestSwift31Linux: XCTestCase {
    static var allTests: [(String, (TestSwift31Linux) -> () throws -> Void)] {
        return [
            ("testGetSwift31LinuxError", testGetSwift31LinuxError)
        ]
    }

    func testGetSwift31LinuxError() {
        #if os(Linux) && swift(>=3.1) && !swift(>=3.1.1)
            let x = expectation(description: "Swift 3.1 on Linux is not supported. Return the appropriate error when trying to send mail on Swift 3.1 Linux.")
            let mail = Mail(from: from, to: [to])
            smtp.send(mail) { (err) in
                if let err = err as? SMTPError, case .swift_3_1_on_linux_not_supported = err {
                    x.fulfill()
                } else {
                    XCTFail("Sending mail on Linux Swift 3.1 should return SMTPError(.swift_3_1_on_linux_not_supported), but returned a different error or no error.")
                }
            }
            waitForExpectations(timeout: testDuration)
        #endif
    }
}
