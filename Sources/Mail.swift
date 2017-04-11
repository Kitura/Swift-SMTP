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
    public let id = UUID().uuidString + ".Kitura-SMTP"
    
    let from: User
    let to: [User]
    let cc: [User]?
    let bcc: [User]?
    let subject: String
    let text: String
    let attachments: [Attachment]?
    let alternative: Attachment?
    let additionalHeaders: [String: String]?
    
    /// Initializes a `Mail` object.
    ///
    /// - Parameters:
    ///     - from: `User` to set the `Mail`'s sender to.
    ///     - to: Array of `User`s to send the `Mail` to.
    ///     - cc: Array of `User`s to cc. (optional)
    ///     - bcc: Array of `User`s to bcc. (optional)
    ///     - subject: Subject of the `Mail`. (optional)
    ///     - text: Text of the `Mail`. (optional)
    ///     - attachments: Array of `Attachment`s for the `Mail`. (optional)
    ///     - additionalHeaders: Additional headers for the `Mail`. (optional)
    public init(from: User, to: [User], cc: [User]? = nil, bcc: [User]? = nil, subject: String = "", text: String = "", attachments: [Attachment]? = nil, additionalHeaders: [String: String]? = nil) {
        self.from = from
        self.to = to
        self.cc = cc
        self.bcc = bcc
        self.subject = subject
        self.text = text
        
        if let attachments = attachments {
            let result = attachments.takeLast { $0.isAlternative }
            self.alternative = result.0
            self.attachments = result.1
        } else {
            self.alternative = nil
            self.attachments = nil
        }
        
        self.additionalHeaders = additionalHeaders
    }
}

extension Mail {
    private var headersDictionary: [String: String] {
        var fields = [String: String]()
        fields["MESSAGE-ID"] = id
        fields["DATE"] = Date().smtpFormatted
        fields["FROM"] = from.mime
        fields["TO"] = to.map { $0.mime }.joined(separator: ", ")
        
        if let cc = cc {
            fields["CC"] = cc.map { $0.mime }.joined(separator: ", ")
        }
        
        fields["SUBJECT"] = subject.mimeEncoded ?? ""
        fields["MIME-VERSION"] = "1.0 (Kitura-SMTP)"
        
        if let additionalHeaders = additionalHeaders {
            for (key, value) in additionalHeaders {
                fields[key.uppercased()] = value
            }
        }
        
        return fields
    }
    
    var headers: String {
        return headersDictionary.map { (key, value) in
            return "\(key): \(value)"
            }.joined(separator: CRLF)
    }
}

extension Mail {
    var hasAttachment: Bool {
        return attachments != nil
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
