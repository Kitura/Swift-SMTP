import XCTest
@testable import KituraSMTPTests

XCTMain([
     testCase(TestAuthEncoder.allTests.shuffled()),
     testCase(TestDataSender.allTests.shuffled()),
     testCase(TestLogin.allTests.shuffled()),
     testCase(TestSender.allTests.shuffled())
])
