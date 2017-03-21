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
    public var attachments: [Attachment]
    public var additionalHeaders: [String: String]
    
    /**
     Initializes a `Mail` object.
     
     - parameters:
        - from: `User` to set the `Mail`'s sender to.
        - to: Array of `User`s to send the `Mail` to.
        - cc: Array of `User`s to cc (optional).
        - bcc: Array of `User`s to bcc (optional).
        - subject: Subject of the `Mail`. Defaults to blank string.
        - text: Text of the `Mail`. Defaults to blank string.
        - attachments: Array of `Attachment`s for the email.
        - additionalHeaders: Additional headers for the email.
     */
    public init(from: User, to: [User], cc: [User] = [], bcc: [User] = [], subject: String = "", text: String = "", attachments: [Attachment] = [], additionalHeaders: [String: String] = [:]) {
        self.from = from
        self.to = to
        self.cc = cc
        self.bcc = bcc
        self.subject = subject
        self.text = text
        self.attachments = attachments
        self.additionalHeaders = additionalHeaders
    }
}

extension Mail {
    func getAttachments() -> ([Attachment], Attachment?) {
        if !attachments.isEmpty {
            let result = attachments.takeLast { $0.isAlternative }
            return (result.1, result.0)
        }
        return ([], nil)
    }
}

private extension Array {
    func takeLast(where condition: (Element) -> Bool) -> (Element?, Array) {
        var index: Int?
        for i in (0 ..< count).reversed() {
            if condition(self[i]) {
                index = i
                break
            }
        }
        
        if let index = index {
            var array = self
            let ele = array.remove(at: index)
            return (ele, array)
        } else {
            return (nil, self)
        }
    }
}

extension Mail {
    private var headersDictionary: [String: String] {
        var fields = [String: String]()
        fields["MESSAGE-ID"] = UUID().uuidString + ".Kitura-SMTP"
        fields["DATE"] = Date().smtpFormatted
        fields["FROM"] = from.mime
        fields["TO"] = to.map { $0.mime }.joined(separator: ", ")
        
        if !cc.isEmpty {
            fields["CC"] = cc.map { $0.mime }.joined(separator: ", ")
        }
        
        fields["SUBJECT"] = subject.mimeEncoded ?? ""
        fields["MIME-VERSION"] = "1.0 (SMTP-Kitura)"
        
        for (key, value) in additionalHeaders {
            fields[key.uppercased()] = value
        }
        
        return fields
    }
    
    var headers: String {
        return headersDictionary.map { (key, value) in
            return "\(key): \(value)"
            }.joined(separator: CRLF)
    }
    
    var hasAttachment: Bool {
        return !attachments.isEmpty
    }
}

private extension DateFormatter {
    static let smtpDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en-US")
        formatter.dateFormat = "EEE, d MMM yyyy HH:mm:ss ZZZ"
        return formatter
    }()
}

private extension Date {
    var smtpFormatted: String {
        return DateFormatter.smtpDateFormatter.string(from: self)
    }
}
