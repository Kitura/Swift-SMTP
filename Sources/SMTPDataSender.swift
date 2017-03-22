import Foundation

struct SMTPDataSender {
    let mail: Mail
    let socket: SMTPSocket
    
    init(mail: Mail, socket: SMTPSocket) {
        self.mail = mail
        self.socket = socket
    }
    
    func send() throws {
        try sendHeader()
        
        if mail.hasAttachment {
            try sendMixed()
        } else {
            try sendText()
        }
    }
}

private extension SMTPDataSender {
    func sendHeader() throws {
        try send(mail.headers)
    }
    
    func sendMixed() throws {
        let boundary = String.createBoundary()
        let mixedHeader = String.mixedHeader(boundary: boundary)
        
        try send(mixedHeader)
        try send(boundary.startLine)
        
        let (attachments, alternative) = mail.getAttachments()
        
        if let alternative = alternative {
            try sendAlternative(alternative)
        } else {
            try sendText()
        }
        try sendAttachments(attachments, boundary: boundary)
    }
    
    func sendAlternative(_ alternative: Attachment) throws {
        let boundary = String.createBoundary()
        let alternativeHeader = String.alternativeHeader(boundary: boundary)
        try send(alternativeHeader)
        
        try send(boundary.startLine)
        try sendText()
        
        try send(boundary.startLine)
        try sendAttachment(alternative)
        
        try send(boundary.endLine)
    }
    
    func sendAttachment(_ attachment: Attachment) throws {
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
        case .file(let file): try sendFile(at: file.path)
        case .html(let html): try sendHTML(html.content)
        case .data(let data): try sendData(data.data)
        }
        
        try send("")
        
        if attachment.hasRelated {
            try sendAttachments(attachment.related, boundary: relatedBoundary)
        }
    }
    
    func sendAttachments(_ attachments: [Attachment], boundary: String) throws {
        for attachement in attachments {
            try send(boundary.startLine)
            try sendAttachment(attachement)
        }
        try send(boundary.endLine)
    }
    
    func sendText() throws {
        let text = mail.text.embeddedText()
        try send(text)
    }
    
    func sendFile(at path: String) throws {
        guard let file = FileHandle(forReadingAtPath: path) else {
            throw SMTPError(.fileNotFound(path))
        }
        let data = file.readDataToEndOfFile().base64EncodedData()
        file.closeFile()
        try send(data)
    }
    
    func sendData(_ data: Data) throws {
        let encodedData = data.base64EncodedData()
        try send(encodedData)
    }
    
    func sendHTML(_ html: String) throws {
        let encodedHTML = html.base64Encoded
        try send(encodedHTML)
    }
}

private extension SMTPDataSender {
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
