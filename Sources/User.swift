//
//  User.swift
//  KituraSMTP
//
//  Created by Quan Vo on 3/8/17.
//
//

import Foundation

public struct User {
    public var name: String?
    public var email: String
    
    public init(name: String? = nil , email: String) {
        self.name = name
        self.email = email
    }
}
