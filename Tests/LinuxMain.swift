import XCTest
@testable import KituraSMTPTests

XCTMain([
     testCase(TestAuthCredentials.allTests),
     testCase(TestDataSender.allTests),
     testCase(TestLogin.allTests),
     testCase(TestSender.allTests)
])
