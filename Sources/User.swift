//
//  User.swift
//  KituraSMTP
//
//  Created by Quan Vo on 3/8/17.
//
//

import Foundation

/// Contains the name and email for a participant in a `Mail`.
public struct User {
    public let name: String
    public let email: String
    
    /**
     Initializes a `User`.
     
     - parameters:
        - name: Display name for the user. Defaults to empty string.
        - email: Email for the user.
     */
    public init(name: String = "" , email: String) {
        self.name = name
        self.email = email
    }
    
    var mime: String {
        if !name.isEmpty, let nameEncoded = name.mimeEncoded {
            return "\(nameEncoded) <\(email)>"
        } else {
            return email
        }        
    }
}

private extension String {
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
}
