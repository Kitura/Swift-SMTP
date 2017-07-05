/**
 * Copyright IBM Corporation 2017
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

import Foundation

/// Represents an email that can be sent through an `SMTP` instance.
public struct Mail {
    /// UUID of the `Mail`.
    public let id = UUID().uuidString + ".Swift-SMTP"

    let from: User
    let to: [User]
    let cc: [User]
    let bcc: [User]
    let subject: String
    let text: String
    let attachments: [Attachment]
    let alternative: Attachment?
    let additionalHeaders: [String: String]

    /// Initializes a `Mail` object.
    ///
    /// - Parameters:
    ///     - from: The `User` that the `Mail` will be sent from.
    ///     - to: Array of `User`s to send the `Mail` to.
    ///     - cc: Array of `User`s to cc. Defaults to none.
    ///     - bcc: Array of `User`s to bcc. Defaults to none.
    ///     - subject: Subject of the `Mail`. Defaults to none.
    ///     - text: Text of the `Mail`. Defaults to none.
    ///     - attachments: Array of `Attachment`s for the `Mail`. If the `Mail`
    ///                    has multiple `Attachment`s that are alternatives to
    ///                    to plain text, the last one will be used as the
    ///                    alternative (all the `Attachments` will still be
    ///                    sent). Defaults to none.
    ///     - additionalHeaders: Additional headers for the `Mail`. Header keys
    ///                          are capitalized and duplicate keys will 
    ///                          overwrite each other. Defaults to none.
    public init(from: User,
                to: [User],
                cc: [User] = [],
                bcc: [User] = [],
                subject: String = "",
                text: String = "",
                attachments: [Attachment] = [],
                additionalHeaders: [String: String] = [:]) {
        self.from = from
        self.to = to
        self.cc = cc
        self.bcc = bcc
        self.subject = subject
        self.text = text

        let (alternative, attachments) = Mail.getAlternative(attachments)
        self.alternative = alternative
        self.attachments = attachments

        self.additionalHeaders = additionalHeaders
    }

    private static func getAlternative(_ attachments: [Attachment]) -> (Attachment?, [Attachment]) {
        let reversed: [Attachment] = attachments.reversed()
        if let index = reversed.index(where: {( $0.isAlternative )}) {
            var newAttachments = attachments
            return (newAttachments.remove(at: index), newAttachments)
        }
        return (nil, attachments)
    }
}

extension Mail {
    private var headersDictionary: [String: String] {
        var dictionary = [String: String]()
        dictionary["MESSAGE-ID"] = id
        dictionary["DATE"] = Date().smtpFormatted
        dictionary["FROM"] = from.mime
        dictionary["TO"] = to.map { $0.mime }.joined(separator: ", ")

        if !cc.isEmpty {
            dictionary["CC"] = cc.map { $0.mime }.joined(separator: ", ")
        }

        dictionary["SUBJECT"] = subject.mimeEncoded ?? ""
        dictionary["MIME-VERSION"] = "1.0 (Swift-SMTP)"

        for (key, value) in additionalHeaders {
            dictionary[key.uppercased()] = value
        }

        return dictionary
    }

    var headersString: String {
        return headersDictionary.map { (key, value) in
            return "\(key): \(value)"
            }.joined(separator: CRLF)
    }
}

extension Mail {
    var hasAttachment: Bool {
        return !attachments.isEmpty || alternative != nil
    }
}

extension DateFormatter {
    static let smtpDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, d MMM yyyy HH:mm:ss ZZZ"
        return formatter
    }()
}

extension Date {
    var smtpFormatted: String {
        return DateFormatter.smtpDateFormatter.string(from: self)
    }
}
