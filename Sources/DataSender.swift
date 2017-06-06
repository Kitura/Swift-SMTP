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

// TODO
// Add code comments

import Foundation

struct DataSender {
    let socket: SMTPSocket
    lazy var cache = NSCache<AnyObject, AnyObject>()

    init(socket: SMTPSocket) {
        self.socket = socket
    }

    mutating func send(_ mail: Mail) throws {
        try sendHeaders(mail.headers)

        if mail.hasAttachment {
            try sendMixed(mail)
        } else {
            try sendText(mail.text)
        }
    }
}

extension DataSender {
    func sendHeaders(_ headers: String) throws {
        try send(headers)
    }

    func sendText(_ text: String) throws {
        let embeddedText = text.embeddedText()
        try send(embeddedText)
    }

    mutating func sendMixed(_ mail: Mail) throws {
        let boundary = String.createBoundary()
        let mixedHeader = String.mixedHeader(boundary: boundary)

        try send(mixedHeader)
        try send(boundary.startLine)

        try sendAlternative(mail)

        if let attachments = mail.attachments {
            try sendAttachments(attachments, boundary: boundary)
        }
    }

    mutating func sendAlternative(_ mail: Mail) throws {
        if let alternative = mail.alternative {
            let boundary = String.createBoundary()
            let alternativeHeader = String.alternativeHeader(boundary: boundary)
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

    mutating func sendAttachments(_ attachments: [Attachment], boundary: String) throws {
        for attachement in attachments {
            try send(boundary.startLine)
            try sendAttachment(attachement)
        }
        try send(boundary.endLine)
    }

    mutating func sendAttachment(_ attachment: Attachment) throws {
        var relatedBoundary = ""

        if attachment.hasRelated {
            relatedBoundary = String.createBoundary()
            let relatedHeader = String.relatedHeader(boundary: relatedBoundary)
            try send(relatedHeader)
            try send(relatedBoundary.startLine)
        }

        let attachmentHeader = attachment.headers + CRLF
        try send(attachmentHeader)

        switch attachment.type {
        case .data(let data): try sendData(data.data)
        case .file(let file): try sendFile(at: file.path)
        case .html(let html): try sendHTML(html.content)
        }

        try send("")

        if let relatedAttachments = attachment.relatedAttachments {
            try sendAttachments(relatedAttachments, boundary: relatedBoundary)
        }
    }

    mutating func sendData(_ data: Data) throws {
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

    mutating func sendFile(at path: String) throws {
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
            throw SMTPError(.fileNotFound(path))
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

    mutating func sendHTML(_ html: String) throws {
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
    func send(_ text: String) throws {
        try socket.write(text)
    }

    func send(_ data: Data) throws {
        try socket.write(data)
    }
}

private extension String {
    static func createBoundary() -> String {
        return UUID().uuidString.replacingOccurrences(of: "-", with: "")
    }

    static let plainTextHeader = "CONTENT-TYPE: text/plain; charset=utf-8\(CRLF)CONTENT-TRANSFER-ENCODING: 7bit\(CRLF)CONTENT-DISPOSITION: inline\(CRLF)"

    static func mixedHeader(boundary: String) -> String {
        return "CONTENT-TYPE: multipart/mixed; boundary=\"\(boundary)\"\(CRLF)"
    }

    static func alternativeHeader(boundary: String) -> String {
        return "CONTENT-TYPE: multipart/alternative; boundary=\"\(boundary)\"\(CRLF)"
    }

    static func relatedHeader(boundary: String) -> String {
        return "CONTENT-TYPE: multipart/related; boundary=\"\(boundary)\"\(CRLF)"
    }

    func embeddedText() -> String {
        return "\(String.plainTextHeader)\(CRLF)\(self)\(CRLF)"
    }
    
    var startLine: String {
        return "--\(self)"
    }
    
    var endLine: String {
        return "--\(self)--"
    }
}
