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

class TestAttachment: XCTestCase {
    static var allTests: [(String, (TestAttachment) -> () throws -> Void)] {
        return [
            ("testDataAttachmentHeaders", testDataAttachmentHeaders),
            ("testFileAttachmentHeaders", testFileAttachmentHeaders),
            ("testHTMLAttachmentHeaders", testHTMLAttachmentHeaders)
        ]
    }

    func testDataAttachmentHeaders() {
        let data = "{\"key\": \"hello world\"}".data(using: .utf8)!
        let headers = Attachment(data: data, mime: "application/json", name: "file.json").headersString
        XCTAssert(headers.contains("CONTENT-TYPE: application/json"))
        XCTAssert(headers.contains("CONTENT-DISPOSITION: attachment; filename=\"=?UTF-8?Q?file.json?=\""))
        XCTAssert(headers.contains("CONTENT-TRANSFER-ENCODING: BASE64"))
    }

    func testFileAttachmentHeaders() {
        let headers = Attachment(filePath: imgFilePath, additionalHeaders: [("CONTENT-ID", "megaman-pic")]).headersString
        XCTAssert(headers.contains("CONTENT-DISPOSITION: attachment; filename=\"=?UTF-8?Q?x.png?=\""))
        XCTAssert(headers.contains("CONTENT-TRANSFER-ENCODING: BASE64"))
        XCTAssert(headers.contains("CONTENT-ID: megaman-pic"))
        XCTAssert(headers.contains("CONTENT-TYPE: application/octet-stream"))
    }

    func testHTMLAttachmentHeaders() {
        let headers = Attachment(htmlContent: html).headersString
        XCTAssert(headers.contains("CONTENT-TYPE: text/html; charset=utf-8"))
        XCTAssert(headers.contains("CONTENT-DISPOSITION: inline"))
        XCTAssert(headers.contains("CONTENT-TRANSFER-ENCODING: BASE64"))

    }
}
