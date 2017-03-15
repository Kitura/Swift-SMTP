//
//  User.swift
//  KituraSMTP
//
//  Created by Quan Vo on 3/8/17.
//
//

import Foundation

public struct User {
    let name: String?
    let email: String
    
    public init(name: String? = nil , email: String) throws {
        try email.validateEmail()
        self.name = name
        self.email = email
    }
}

private extension String {
    func validateEmail() throws {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        guard emailTest.evaluate(with: self) else {
            throw NSError("Invalid email: \(self).")
        }
    }
}
