//
//  SMTPResponse.swift
//  KituraSMTP
//
//  Created by Quan Vo on 3/9/17.
//
//

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
