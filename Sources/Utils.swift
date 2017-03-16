//
//  Constant.swift
//  KituraSMTP
//
//  Created by Quan Vo on 3/9/17.
//
//

import Foundation

let CRLF = "\r\n"

extension DateFormatter {
    static let smtpDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, d MMM yyyy HH:mm:ss ZZZ"
        return formatter
    }()
}

extension Date {
    func toString() -> String {
        return DateFormatter.smtpDateFormatter.string(from: self)
    }
}

extension NSError {
    convenience init(_ err: String) {
        #if os(Linux)
            let userInfo: [String: Any]
        #else
            let userInfo: [String: String]
        #endif
        userInfo = [NSLocalizedDescriptionKey: err]
        self.init(domain: "KituraSMTP", code: 0, userInfo: userInfo)
    }
}
