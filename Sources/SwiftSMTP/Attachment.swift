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

/// Represents a `Mail`'s attachment.
/// Different SMTP servers have different attachment size limits.
public struct Attachment {
    let type: AttachmentType
    let additionalHeaders: [String: String]
    let relatedAttachments: [Attachment]

    /// Initialize a data `Attachment`.
    ///
    /// - Parameters:
    ///     - data: Raw data to be sent as attachment.
    ///     - mime: MIME type of the data.
    ///     - name: File name which will be presented in the mail.
    ///     - inline: Indicates if attachment is inline. To embed the attachment
    ///               in mail content, set to `true`. To send as standalone
    ///               attachment, set to `false`. Defaults to `false`.
    ///     - additionalHeaders: Additional headers for the `Mail`. Header keys
    ///                          are capitalized and duplicate keys will
    ///                          overwrite each other. Defaults to none. The
    ///                          following will be ignored: CONTENT-TYPE,
    ///                          CONTENT-DISPOSITION, CONTENT-TRANSFER-ENCODING.
    ///     - related: Related `Attachment`s of this attachment. Defaults to
    ///                none.
    public init(data: Data,
                mime: String,
                name: String,
                inline: Bool = false,
                additionalHeaders: [String: String] = [:],
                relatedAttachments: [Attachment] = []) {
        self.init(type: .data(data: data,
                              mime: mime,
                              name: name,
                              inline: inline),
                  additionalHeaders: additionalHeaders,
                  relatedAttachments: relatedAttachments)
    }

    /// Initialize an `Attachment` from a local file.
    ///
    /// - Parameters:
    ///     - filePath: Path to the local file.
    ///     - mime: MIME type of the file. Defaults to
    ///             `application/octet-stream`.
    ///     - name: Name of the file. Defaults to the name component in its
    ///             file path.
    ///     - inline: Indicates if attachment is inline. To embed the attachment
    ///               in mail content, set to `true`. To send as standalone
    ///               attachment, set to `false`. Defaults to `false`.
    ///     - additionalHeaders: Additional headers for the attachment. Header
    ///                          keys are capitalized and duplicate keys will
    ///                          replace each other. Defaults to none.
    ///     - related: Related `Attachment`s of this attachment. Defaults to
    ///                none.
    public init(filePath: String,
                mime: String = "application/octet-stream",
                name: String? = nil,
                inline: Bool = false,
                additionalHeaders: [String: String] = [:],
                relatedAttachments: [Attachment] = []) {
        let name = name ?? NSString(string: filePath).lastPathComponent
        self.init(type: .file(path: filePath,
                              mime: mime,
                              name: name,
                              inline: inline),
                  additionalHeaders: additionalHeaders,
                  relatedAttachments: relatedAttachments)
    }

    /// Initialize an HTML `Attachment`.
    ///
    /// - Parameters:
    ///     - htmlContent: Content string of HTML.
    ///     - characterSet: Character encoding of `htmlContent`. Defaults to
    ///                     `utf-8`.
    ///     - alternative: Whether the HTML is an alternative for plain text or
    ///                    not. Defaults to `true`.
    ///     - additionalHeaders: Additional headers for the attachment. Header
    ///                          keys are capitalized and duplicate keys will
    ///                          replace each other. Defaults to none.
    ///     - related: Related `Attachment`s of this attachment. Defaults to
    ///                none.
    public init(htmlContent: String,
                characterSet: String = "utf-8",
                alternative: Bool = true,
                additionalHeaders: [String: String] = [:],
                relatedAttachments: [Attachment] = []) {
        self.init(type: .html(content: htmlContent,
                              characterSet: characterSet,
                              alternative: alternative),
                  additionalHeaders: additionalHeaders,
                  relatedAttachments: relatedAttachments)
    }

    private init(type: AttachmentType,
                 additionalHeaders: [String: String],
                 relatedAttachments: [Attachment]) {
        self.type = type
        self.additionalHeaders = additionalHeaders
        self.relatedAttachments = relatedAttachments
    }
}

extension Attachment {
    enum AttachmentType {
        case data(data: Data, mime: String, name: String, inline: Bool)
        case file(path: String, mime: String, name: String, inline: Bool)
        case html(content: String, characterSet: String, alternative: Bool)
    }
}

extension Attachment {
    private var headersDictionary: [String: String] {
        var dictionary = [String: String]()
        switch type {

        case .data(let data):
            dictionary["CONTENT-TYPE"] = data.mime
            var attachmentDisposition = data.inline ? "inline" : "attachment"
            if let mime = data.name.mimeEncoded {
                attachmentDisposition.append("; filename=\"\(mime)\"")
            }
            dictionary["CONTENT-DISPOSITION"] = attachmentDisposition

        case .file(let file):
            dictionary["CONTENT-TYPE"] = file.mime
            var attachmentDisposition = file.inline ? "inline" : "attachment"
            if let mime = file.name.mimeEncoded {
                attachmentDisposition.append("; filename=\"\(mime)\"")
            }
            dictionary["CONTENT-DISPOSITION"] = attachmentDisposition

        case .html(let html):
            dictionary["CONTENT-TYPE"] = "text/html; charset=\(html.characterSet)"
            dictionary["CONTENT-DISPOSITION"] = "inline"
        }

        dictionary["CONTENT-TRANSFER-ENCODING"] = "BASE64"

        for (key, value) in additionalHeaders {
            let keyUppercased = key.uppercased()
            if  keyUppercased != "CONTENT-TYPE" &&
                keyUppercased != "CONTENT-DISPOSITION" &&
                keyUppercased != "CONTENT-TRANSFER-ENCODING" {
                dictionary[keyUppercased] = value
            }
        }

        return dictionary
    }

    var headersString: String {
        return headersDictionary.map { (key, value) in
            return "\(key): \(value)"
            }.joined(separator: CRLF)
    }
}

extension Attachment {
    var hasRelated: Bool {
        return !relatedAttachments.isEmpty
    }

    var isAlternative: Bool {
        if case .html(let html) = type, html.alternative {
            return true
        }
        return false
    }
}

extension Attachment: Equatable {
    /// Returns `true` if the `Attachment`s are equal.
    public static func ==(lhs: Attachment, rhs: Attachment) -> Bool {
        return lhs.additionalHeaders == rhs.additionalHeaders &&
            lhs.hasRelated == rhs.hasRelated &&
            lhs.headersDictionary == rhs.headersDictionary &&
            lhs.isAlternative == rhs.isAlternative &&
            lhs.relatedAttachments == rhs.relatedAttachments &&
            lhs.type == rhs.type
    }
}

extension Attachment.AttachmentType: Equatable {
    static func ==(lhs: Attachment.AttachmentType, rhs: Attachment.AttachmentType) -> Bool {
        switch (lhs, rhs) {
        case (let .data(data1, mime1, name1, inline1), let .data(data2, mime2, name2, inline2)):
            return data1 == data2 &&
                mime1 == mime2 &&
                name1 == name2 &&
                inline1 == inline2
        case (let .file(path1, mime1, name1, inline1), let .file(path2, mime2, name2, inline2)):
            return path1 == path2 &&
                mime1 == mime2 &&
                name1 == name2 &&
                inline1 == inline2
        case (let .html(content1, characterSet1, alternative1),
              let .html(content2, characterSet2, alternative2)):
            return content1 == content2 &&
                characterSet1 == characterSet2 &&
                alternative1 == alternative2
        default:
            return false
        }
    }
}
