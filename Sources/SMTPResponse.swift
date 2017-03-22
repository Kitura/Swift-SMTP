import Foundation

struct SMTPResponse {
    let code: SMTPResponseCode
    let message: String
    let response: String
    
    init(code: SMTPResponseCode, message: String, response: String) {
        self.code = code
        self.message = message
        self.response = response
    }
}

struct SMTPResponseCode: Equatable {
    let rawValue: Int
    init(_ value: Int) { rawValue = value }
    
    static let serviceReady = SMTPResponseCode(220)
    static let connectionClosing = SMTPResponseCode(221)
    static let authSucceeded = SMTPResponseCode(235)
    static let commandOK = SMTPResponseCode(250)
    static let willForward = SMTPResponseCode(251)
    static let containingChallenge = SMTPResponseCode(334)
    static let startMailInput = SMTPResponseCode(354)
    
    public static func ==(lhs: SMTPResponseCode, rhs: SMTPResponseCode) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}
