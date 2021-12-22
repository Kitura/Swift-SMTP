/**
 * Copyright Stephen Beitzel 2021
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

@testable import SwiftSMTP
import XCTest

class TestWrapUnwrap: XCTestCase {
    var reallyLongLine: String = ""

    override func setUpWithError() throws {
        let address = "test_address@dumbster.local"
        reallyLongLine = "To: "
        for _ in 1...34 {
            reallyLongLine.append(address)
            reallyLongLine.append(", ")
        }
        reallyLongLine.append(address)
    }

    func testWrap() throws {
        let wrapped = reallyLongLine.wrap(78)
        let lines = wrapped.split(separator: "\r\n")
        XCTAssertEqual(lines.count, 14)
    }

    func testUnwrap() throws {
        let wrapped = "Subject: This\r\n  is a test"
        let unwrapped = wrapped.unwrap()

        XCTAssertEqual(unwrapped, "Subject: This is a test")
    }
}
