import XCTest
@testable import KituraSMTPTests

XCTMain([
     testCase(TestAuthEncoder.allTests),
     testCase(TestDataSender.allTests),
     testCase(TestLogin.allTests),
     testCase(TestSender.allTests)
])
