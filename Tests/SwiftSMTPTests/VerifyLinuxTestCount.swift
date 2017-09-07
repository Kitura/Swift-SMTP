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

#if os(OSX) && !swift(>=3.2)
    import XCTest
    
    class VerifyLinuxTextCount: XCTestCase {
        func verifyLinuxTextCount() {
            var linuxCount: Int
            var darwinCount: Int
            
            // TestAttachment
            linuxCount = TestAttachment.allTests.count
            darwinCount = Int(TestAttachment.defaultTestSuite().testCaseCount)
            XCTAssertEqual(linuxCount, darwinCount, "\(darwinCount - linuxCount) tests are missing from TestAttachment.allTests")
            
            // TestAuthEncoder
            linuxCount = TestAuthEncoder.allTests.count
            darwinCount = Int(TestAuthEncoder.defaultTestSuite().testCaseCount)
            XCTAssertEqual(linuxCount, darwinCount, "\(darwinCount - linuxCount) tests are missing from TestAuthEncoder.allTests")
            
            // TestDataSender
            linuxCount = TestDataSender.allTests.count
            darwinCount = Int(TestDataSender.defaultTestSuite().testCaseCount)
            XCTAssertEqual(linuxCount, darwinCount, "\(darwinCount - linuxCount) tests are missing from TestDataSender.allTests")
            
            // TestLogin
            linuxCount = TestLogin.allTests.count
            darwinCount = Int(TestLogin.defaultTestSuite().testCaseCount)
            XCTAssertEqual(linuxCount, darwinCount, "\(darwinCount - linuxCount) tests are missing from TestLogin.allTests")
            
            // TestMiscellaneous
            linuxCount = TestMiscellaneous.allTests.count
            darwinCount = Int(TestMiscellaneous.defaultTestSuite().testCaseCount)
            XCTAssertEqual(linuxCount, darwinCount, "\(darwinCount - linuxCount) tests are missing from TestMiscellaneous.allTests")
            
            // TestSender
            linuxCount = TestSender.allTests.count
            darwinCount = Int(TestSender.defaultTestSuite().testCaseCount)
            XCTAssertEqual(linuxCount, darwinCount, "\(darwinCount - linuxCount) tests are missing from TestSender.allTests")
            
            // TestSMTPSocket
            linuxCount = TestSMTPSocket.allTests.count
            darwinCount = Int(TestSMTPSocket.defaultTestSuite().testCaseCount)
            XCTAssertEqual(linuxCount, darwinCount, "\(darwinCount - linuxCount) tests are missing from TestSMTPSocket.allTests")
        }
    }
#endif
