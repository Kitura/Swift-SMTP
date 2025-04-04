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
import LoggerAPI

/// Represents an email that can be sent through an `SMTP` instance.
public struct Mail {
    /// A UUID for the mail.
    public let uuid = UUID().uuidString

    /// The `User` that the `Mail` will be sent from.
    public let from: User

    /// Array of `User`s to send the `Mail` to.
    public let to: [User]

    /// Array of `User`s to cc. Defaults to none.
    public let cc: [User]

    /// Array of `User`s to bcc. Defaults to none.
    public let bcc: [User]

    /// Subject of the `Mail`. Defaults to none.
    public let subject: String

    /// Text of the `Mail`. Defaults to none.
    public let text: String

    /// Array of `Attachment`s for the `Mail`. If the `Mail` has multiple `Attachment`s that are alternatives to plain
    /// text, the last one will be used as the alternative (all the `Attachments` will still be sent). Defaults to none.
    public let attachments: [Attachment]

    /// Attachment that is an alternative to plain text.
    public let alternative: Attachment?

    /// Additional headers for the `Mail`. Header keys are capitalized and duplicate keys will overwrite each other.
    /// Defaults to none. The following will be ignored: CONTENT-TYPE, CONTENT-DISPOSITION, CONTENT-TRANSFER-ENCODING.
    public let additionalHeaders: [String: String]

    /// message-id https://tools.ietf.org/html/rfc5322#section-3.6.4
    public var id: String {
        return "<\(uuid).Swift-SMTP@\(hostname)>"
    }

    /// Hostname from the email address.
    public var hostname: String {
        let fullEmail = from.email
#if swift(>=4.2)
        let atIndex = fullEmail.firstIndex(of: "@")
#else
        let atIndex = fullEmail.index(of: "@")
#endif
        let hostStart = fullEmail.index(after: atIndex!)
        return String(fullEmail[hostStart...])
    }

    /// Initializes a `Mail` object.
    ///
    /// - Parameters:
    ///     - from: The `User` that the `Mail` will be sent from.
    ///     - to: Array of `User`s to send the `Mail` to.
    ///     - cc: Array of `User`s to cc. Defaults to none.
    ///     - bcc: Array of `User`s to bcc. Defaults to none.
    ///     - subject: Subject of the `Mail`. Defaults to none.
    ///     - text: Text of the `Mail`. Defaults to none.
    ///     - attachments: Array of `Attachment`s for the `Mail`. If the `Mail` has multiple `Attachment`s that are
    ///       alternatives to plain text, the last one will be used as the alternative (all the `Attachments` will still
    ///       be sent). Defaults to none.
    ///     - additionalHeaders: Additional headers for the `Mail`. Header keys are capitalized and duplicate keys will
    ///       overwrite each other. Defaults to none. The following will be ignored: CONTENT-TYPE, CONTENT-DISPOSITION,
    ///       CONTENT-TRANSFER-ENCODING.
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
        var reversed: [Attachment] = attachments.reversed()
#if swift(>=4.2)
        let index = reversed.firstIndex(where: { $0.isAlternative })
#else
        let index = reversed.index(where: { $0.isAlternative })
#endif
        if let index = index {
            return (reversed.remove(at: index), reversed.reversed())
        }
        return (nil, attachments)
    }

    private var headersDictionary: [String: String] {
        var dictionary = [String: String]()
        dictionary["MESSAGE-ID"] = id
        dictionary["DATE"] = Date().smtpFormatted
        dictionary["FROM"] = from.mime
        dictionary["TO"] = foldHeaderValue(key: "TO", value: to.map { $0.mime }.joined(separator: ", "))

        if !cc.isEmpty {
            dictionary["CC"] = foldHeaderValue(key: "CC", value: cc.map { $0.mime }.joined(separator: ", "))
        }

        dictionary["SUBJECT"] = foldHeaderValue(key: "SUBJECT", value: (subject.mimeEncoded ?? ""))
        dictionary["MIME-VERSION"] = "1.0 (Swift-SMTP)"

        for (key, value) in additionalHeaders {
            let keyUppercased = key.uppercased()
            if  keyUppercased != "CONTENT-TYPE" &&
                keyUppercased != "CONTENT-DISPOSITION" &&
                keyUppercased != "CONTENT-TRANSFER-ENCODING" {
                dictionary[keyUppercased] = foldHeaderValue(key: key, value: value)
            }
        }

        return dictionary
    }

    private func foldHeaderValue(key: String, value: String) -> String {
        let suggestedLineLength = 78
        let maximumLineLength = 998

        let initialHeader = "\(key): \(value)"
        if initialHeader.count <= suggestedLineLength {
            return value
        }
        // if we're here, it means that RFC 5322 SUGGESTS that we fold this header
        var foldedHeader = ""
        var register = "\(key): "
        var linePosition = 0
        let foldableCharacters = CharacterSet(charactersIn: " ,")
        for char in value {
            // append the character to the register
            register.append(char)
            // this test is to detect the end of a token, mid-stream
            if let _ = String(char).rangeOfCharacter(from: foldableCharacters) {
                if linePosition > 1 && (register.count + linePosition > suggestedLineLength) {
                    // We already have stuff on the line and the register is too long
                    // to continue on the current line. So we fold and start a new line.
                    foldedHeader.append("\r\n ")
                    linePosition = 1
                }
                // now, register contains a complete token, so we put it up to the line
                linePosition += register.count
                if linePosition > maximumLineLength {
                    Log.error("Header line length exceeds the specified maximum (998 chars) - see RFC 5322 section 2.2.3")
                }
                foldedHeader.append(register)
                register = ""
            }
        }
        // We have the last of the value characters in register, so we put them up
        // to the line. We still want to apply the same logic as that inside the loop
        // though, and apply folding if it's appropriate.
        if linePosition > 1 && (register.count + linePosition > suggestedLineLength) {
            foldedHeader.append("\r\n ")
            linePosition = 1
        }
        if (register.count + linePosition) > maximumLineLength {
            Log.error("Header line length exceeds the specified maximum (998 chars) - see RFC 5322 section 2.2.3")
        }
        foldedHeader.append(register)

        // Here is where we remove "\(key): " from the beginning of the folded header,
        // so we only return the value.
        let valueIndex = foldedHeader.index(foldedHeader.startIndex, offsetBy: key.count + 2)
        return String(foldedHeader.suffix(from: valueIndex))
    }

    var headersString: String {
        return headersDictionary.map { (key, value) in
            return "\(key): \(value)"
            }.joined(separator: CRLF)
    }

    var hasAttachment: Bool {
        return !attachments.isEmpty || alternative != nil
    }
}

extension Mail {
    /// Represents a sender or receiver of an email.
    public struct User {
        /// The user's name that is displayed in an email. Optional.
        public let name: String?

        /// The user's email address.
        public let email: String

        ///  Initializes a `User`.
        ///
        /// - Parameters:
        ///     - name: The user's name that is displayed in an email. Optional.
        ///     - email: The user's email address.
        public init(name: String? = nil, email: String) {
            self.name = name
            self.email = email
        }

        var mime: String {
            if let name = name, let nameEncoded = name.mimeEncoded {
                return "\(nameEncoded) <\(email)>"
            } else {
                return email
            }
        }
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
