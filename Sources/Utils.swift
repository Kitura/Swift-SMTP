//
//  Utils.swift
//  KituraSMTP
//
//  Created by Quan Vo on 3/21/17.
//
//

import Foundation

let CRLF = "\r\n"

extension String {
    var mimeEncoded: String? {
        guard let encoded = addingPercentEncoding(
            withAllowedCharacters: .urlQueryAllowed) else {
                return nil
        }
        
        let quoted = encoded
            .replacingOccurrences(of: "%20", with: "_")
            .replacingOccurrences(of: ",", with: "%2C")
            .replacingOccurrences(of: "%", with: "=")
        return "=?UTF-8?Q?\(quoted)?="
    }
    
    var base64Encoded: String {
        return Data(utf8).base64EncodedString()
    }
}
