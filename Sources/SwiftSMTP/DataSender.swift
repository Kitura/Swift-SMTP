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

// Used to send the content of an email--headers, text, and attachments.
// Should only be invoked after sending the `DATA` command to the server.
// The email is not actually sent until we have indicated that we are done sending its contents with a `CRLF CRLF`.
// This is handled by `Sender`.
struct DataSender {
    // Socket we use to read and write data to
    private let socket: SMTPSocket

    // Init a new instance of `DataSender`
    init(socket: SMTPSocket) {
        self.socket = socket
    }

    // Send the text and attachments of the `mail`
    func send(_ mail: Mail) throws {
        try sendHeaders(mail.headersString)

        if mail.hasAttachment {
            try sendMixed(mail)
        } else {
            try sendText(mail.text)
        }
    }
}

extension DataSender {
    // Send the headers of a `Mail`
    func sendHeaders(_ headers: String) throws {
        try send(headers)
    }

    // Add custom/default headers to a `Mail`'s text and write it to the socket.
    func sendText(_ text: String) throws {
        try send(text.embedded)
    }

    // Send `mail`'s content that is more than just plain text
    func sendMixed(_ mail: Mail) throws {
        let boundary = String.makeBoundary()
        let mixedHeader = String.makeMixedHeader(boundary: boundary)

        try send(mixedHeader)
        try send(boundary.startLine)

        try sendAlternative(for: mail)

        try sendAttachments(mail.attachments, boundary: boundary)
    }

    // If `mail` has an attachment that is an alternative to plain text, sends that attachment and the plain text.
    // Else just sends the plain text.
    func sendAlternative(for mail: Mail) throws {
        if let alternative = mail.alternative {
            let boundary = String.makeBoundary()
            let alternativeHeader = String.makeAlternativeHeader(boundary: boundary)
            try send(alternativeHeader)

            try send(boundary.startLine)
            try sendText(mail.text)

            try send(boundary.startLine)
            try sendAttachment(alternative)

            try send(boundary.endLine)
            return
        }

        try sendText(mail.text)
    }

    // Sends the attachments of a `Mail`.
    func sendAttachments(_ attachments: [Attachment], boundary: String) throws {
        for attachment in attachments {
            try send(boundary.startLine)
            try sendAttachment(attachment)
        }
        try send(boundary.endLine)
    }

    // Send the `attachment`.
    func sendAttachment(_ attachment: Attachment) throws {
        var relatedBoundary = ""

        if attachment.hasRelated {
            relatedBoundary = String.makeBoundary()
            let relatedHeader = String.makeRelatedHeader(boundary: relatedBoundary)
            try send(relatedHeader)
            try send(relatedBoundary.startLine)
        }

        let attachmentHeader = attachment.headersString + CRLF
        try send(attachmentHeader)

        switch attachment.type {
        case .data(let data): try sendData(data.data)
        case .file(let file): try sendFile(at: file.path)
        case .html(let html): try sendHTML(html.content)
        }

        try send("")

        if attachment.hasRelated {
            try sendAttachments(attachment.relatedAttachments, boundary: relatedBoundary)
        }
    }

    // Send a data attachment. Data must be base 64 encoded before sending.
    // Checks if the base 64 encoded version has been cached first.
    func sendData(_ data: Data) throws {
        #if os(macOS)
            if let encodedData = cache.object(forKey: data as AnyObject) as? Data {
                return try send(encodedData)
            }
        #else
            if let encodedData = cache.object(forKey: NSData(data: data) as AnyObject) as? Data {
                return try send(encodedData)
            }
        #endif

        let encodedData = data.base64EncodedData()
        try send(encodedData)

        #if os(macOS)
            cache.setObject(encodedData as AnyObject, forKey: data as AnyObject)
        #else
            cache.setObject(NSData(data: encodedData) as AnyObject, forKey: NSData(data: data) as AnyObject)
        #endif
    }

    // Sends a local file at the given path. File must be base 64 encoded before sending. Checks the cache first.
    // Throws an error if file could not be found.
    func sendFile(at path: String) throws {
        #if os(macOS)
            if let data = cache.object(forKey: path as AnyObject) as? Data {
                return try send(data)
            }
        #else
            if let data = cache.object(forKey: NSString(string: path) as AnyObject) as? Data {
                return try send(data)
            }
        #endif

        guard let file = FileHandle(forReadingAtPath: path) else {
            throw SMTPError.fileNotFound(path: path)
        }

        let data = file.readDataToEndOfFile().base64EncodedData()
        try send(data)
        file.closeFile()

        #if os(macOS)
            cache.setObject(data as AnyObject, forKey: path as AnyObject)
        #else
            cache.setObject(NSData(data: data) as AnyObject, forKey: NSString(string: path) as AnyObject)
        #endif
    }

    // Send an HTML attachment. HTML must be base 64 encoded before sending.
    // Checks if the base 64 encoded version is in cache first.
    func sendHTML(_ html: String) throws {
        #if os(macOS)
            if let encodedHTML = cache.object(forKey: html as AnyObject) as? String {
                return try send(encodedHTML)
            }
        #else
            if let encodedHTML = cache.object(forKey: NSString(string: html) as AnyObject) as? String {
                return try send(encodedHTML)
            }
        #endif

        let encodedHTML = html.base64Encoded
        try send(encodedHTML)

        #if os(macOS)
            cache.setObject(encodedHTML as AnyObject, forKey: html as AnyObject)
        #else
            cache.setObject(NSString(string: encodedHTML) as AnyObject, forKey: NSString(string: html) as AnyObject)
        #endif
    }
}

private extension DataSender {
    // Write `text` to the socket.
    func send(_ text: String) throws {
        try socket.write(text)
    }

    // Write `data` to the socket.
    func send(_ data: Data) throws {
        try socket.write(data)
    }
}

private extension String {
    // Embed plain text content of emails with the proper headers so that it is entered correctly.
    var embedded: String {
        var embeddedText = ""
        embeddedText += "CONTENT-TYPE: text/plain; charset=utf-8\(CRLF)"
        embeddedText += "CONTENT-TRANSFER-ENCODING: 7bit\(CRLF)"
        embeddedText += "CONTENT-DISPOSITION: inline\(CRLF)"
        embeddedText += "\(CRLF)\(self)\(CRLF)"
        return embeddedText
    }

    // The SMTP protocol requires unique boundaries between sections of an email.
    static func makeBoundary() -> String {
        return UUID().uuidString.replacingOccurrences(of: "-", with: "")
    }

    // Header for a mixed type email.
    static func makeMixedHeader(boundary: String) -> String {
        return "CONTENT-TYPE: multipart/mixed; boundary=\"\(boundary)\"\(CRLF)"
    }

    // Header for an alternative email.
    static func makeAlternativeHeader(boundary: String) -> String {
        return "CONTENT-TYPE: multipart/alternative; boundary=\"\(boundary)\"\(CRLF)"
    }

    // Header for an attachment that is related to another attachment. (Such as an image attachment that can be
    // referenced by a related HTML attachment)
    static func makeRelatedHeader(boundary: String) -> String {
        return "CONTENT-TYPE: multipart/related; boundary=\"\(boundary)\"\(CRLF)"
    }

    // Added to a boundary to indicate the beginning of the corresponding section.
    var startLine: String {
        return "--\(self)"
    }

    // Added to a boundary to indicate the end of the corresponding section.
    var endLine: String {
        return "--\(self)--"
    }
}
