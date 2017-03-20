//
//  Email.swift
//  KituraSMTP
//
//  Created by Quan Vo on 3/8/17.
//
//

import Foundation

/// Mail object that can be sent through an `SMTP` instance.
public struct Mail {
    public var from: User
    public var to: [User]
    public var cc: [User]
    public var bcc: [User]
    public var subject: String
    public var text: String
    
    /**
     Initializes a `Mail` object.
     
     - parameters:
        - from: `User` to set the `Mail`'s sender to.
        - to: Array of `User`s to send the `Mail` to.
        - cc: Array of `User`s to cc. Defaults to [].
        - bcc: Array of `User`s to bcc. Defaults to [].
        - subject: Subject of the `Mail`. Defaults to blank string.
        - text: Text of the `Mail`. Defaults to blank string.
     */
    public init(from: User, to: [User], cc: [User] = [], bcc: [User] = [], subject: String = "", text: String = "") {
        self.from = from
        self.to = to
        self.cc = cc
        self.bcc = bcc
        self.subject = subject
        self.text = text
    }
}
