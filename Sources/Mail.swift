//
//  Email.swift
//  KituraSMTP
//
//  Created by Quan Vo on 3/8/17.
//
//

import Foundation

public struct Mail {
    var from: User
    var to: [User]
    var subject: String
    var text: String
    
    public init(from: User, to: User, subject: String = "", text: String = "") {
        self.from = from
        self.to = [to]
        self.subject = subject
        self.text = text
    }
    
    public init(from: User, to: [User], subject: String = "", text: String = "") {
        self.from = from
        self.to = to
        self.subject = subject
        self.text = text
    }
}
