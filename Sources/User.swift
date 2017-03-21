//
//  User.swift
//  KituraSMTP
//
//  Created by Quan Vo on 3/21/17.
//
//

import Foundation

/// Contains the name and email for a participant in a `Mail`.
public struct User {
    public var name: String
    public var email: String
    
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
