//
//  User.swift
//  KituraSMTP
//
//  Created by Quan Vo on 3/8/17.
//
//

import Foundation

struct User {
    let name: String
    let email: String
    
    init(name: String="", email: String) throws {
        self.email = try email.validateEmail()
        
        if name == "" {
            self.name = email
        } else {
            self.name = name
        }
    }
}

private extension String {
    func validateEmail() throws -> String {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        guard emailTest.evaluate(with: self) else {
            throw NSError("Invalid email: \(self).")
        }
        return self
    }
}
