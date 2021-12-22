//
//  TestWrapUnwrap.swift
//  SwiftSMTPTests
//
//  Created by Stephen Beitzel on 12/22/21.
//

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
