//
//  CryptoEncoder.swift
//  KituraSMTP
//
//  Created by Quan Vo on 3/8/17.
//
//

import Foundation

struct CryptoEncoder {
    static func login(user: String, password: String) -> (encodedUser: String, encodedPassword: String) {
        return (user.base64EncodedString, password.base64EncodedString)
    }
    
    static func plain(user: String, password: String) -> String {
        let text = "\u{0000}\(user)\u{0000}\(password)"
        return text.base64EncodedString
    }
    
    static func xOauth2(user: String, password: String) -> String {
        let text = "user=\(user)\u{0001}auth=Bearer \(password)\u{0001}\u{0001}"
        return text.base64EncodedString
    }
}

private extension String {
    var base64EncodedString: String {
        return Data(utf8).base64EncodedString()
    }
}
