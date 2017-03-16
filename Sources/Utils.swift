//
//  Constant.swift
//  KituraSMTP
//
//  Created by Quan Vo on 3/9/17.
//
//

import Foundation

let CRLF = "\r\n"

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
