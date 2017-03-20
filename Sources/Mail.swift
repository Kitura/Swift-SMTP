//
//  Email.swift
//  KituraSMTP
//
//  Created by Quan Vo on 3/8/17.
//
//

import Foundation

public struct Mail {
    public var from: User
    public var to: [User]
    public var cc: [User]
    public var bcc: [User]
    public var subject: String
    public var text: String
    
    public init(from: User, to: [User], cc: [User] = [], bcc: [User] = [], subject: String = "", text: String = "") {
        self.from = from
        self.to = to
        self.cc = cc
        self.bcc = bcc
        self.subject = subject
        self.text = text
    }
}
