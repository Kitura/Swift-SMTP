import Foundation

/// Represents a `Mail`'s attachment.
public struct Attachment {
    public var type: AttachmentType
    public var additionalHeaders: [String: String]
    public var related: [Attachment]
    
    var hasRelated: Bool {
        return !related.isEmpty
    }
    
    var isAlternative: Bool {
        if case .html(let p) = type, p.alternative { return true }
        return false
    }
    
    /**
     Initialize an attachment from a local file.
     
     - parameters:
        - filePath: Path to the local file.
        - mime: MIME type of the file. Default is "application/octet-stream".
        - name: Name of the file. Defaults to the name component in its path.
        - inline: Indicates if attachment is inline. To embed the attachment in
                  mail content, set to true. To send as standalone attachment, 
                  set to false. Defaults to `true`.
        - additionalHeaders: Additional headers for the attachment. For example, 
                             if the attachment is related to another attachment,
                             add "CONTENT-ID": "my-id-here" to reference this
                             attachment by "cid:my-id-here" from the other
                             attachment. (optional)
        - related: Related attachments of this attachment. (optional)
     */
    public init(filePath: String, mime: String = "application/octet-stream", name: String? = nil, inline: Bool = false, additionalHeaders: [String: String] = [:], related: [Attachment] = []) {
        let name = name ?? NSString(string: filePath).lastPathComponent
        let fileProperty = FileProperty(path: filePath, mime: mime, name: name, inline: inline)
        self.init(type: .file(fileProperty), additionalHeaders: additionalHeaders, related: related)
    }
    
    /**
     Initialize an HTML attachment.
     
     - parameters:
        - htmlContent: Content string of HTML.
        - characterSet: Character encoding of `htmlContent`. Default is "utf-8".
        - alternative: Whether the HTML is an alternative for plain text or not.
                       Defaults to `true`.
        - additionalHeaders: Additional headers for the attachment. For example,
                             if the attachment is related to another attachment,
                             add "CONTENT-ID": "my-id-here" to reference this
                             attachment by "cid:my-id-here" from the other
                             attachment. (optional)
        - related: Related attachments of this attachment. (optional)
     */
    public init(htmlContent: String, characterSet: String = "utf-8", alternative: Bool = true, additionalHeaders: [String: String] = [:], related: [Attachment] = []) {
        let htmlProperty = HTMLProperty(content: htmlContent, characterSet: characterSet, alternative: alternative)
        self.init(type: .html(htmlProperty), additionalHeaders: additionalHeaders, related: related)
    }
    
    /// Initilize a data attachment.
    ///
    /// - Parameters:
    ///   - data: Raw data will be sent as attachment.
    ///   - mime: MIME type of the data.
    ///   - name: File name which will be presented in the mail.
    ///   - inline: Whether the file could be inline or not. When set to `true`,
    ///             the attachment “Content-Disposition” header will be `inline`,
    ///             otherwise it will be `attachment`. If you want to embed the
    ///             file in mail content, set it to `true`. Otherwise if you
    ///             need it to be a standalone attachment, `false`.
    ///   - additionalHeaders: Additional headers when sending current
    ///                        attachment with a `Mail`.
    ///   - related: Related attachments of current attachment. The `related`
    ///              ones will be contained in a "related" boundary in the mail
    ///              body.
    public init(data: Data, mime: String, name: String, inline: Bool = false, additionalHeaders: [String: String] = [:], related: [Attachment] = []) {
        let dataProperty = DataProperty(data: data, mime: mime, name: name, inline: inline)
        self.init(type: .data(dataProperty), additionalHeaders: additionalHeaders, related: related)
    }
    
    /// Initilize an attachment with an `AttachmentType`.
    ///
    /// - Parameters:
    ///   - type: The type of attachement.
    ///   - additionalHeaders: Additional headers when sending current
    ///                        attachment with a `Mail`.
    ///   - related: Related attachments of current attachment. The `related`
    ///              ones will be contained in a "related" boundary in the mail
    ///              body.
    public init(type: AttachmentType, additionalHeaders: [String: String] = [:], related: [Attachment] = []) {
        self.type = type
        self.additionalHeaders = additionalHeaders
        self.related = related
    }
}

public extension Attachment {
    /// Attachment type with corresponding properties.
    public enum AttachmentType {
        case file(FileProperty)
        case html(HTMLProperty)
        case data(DataProperty)
    }
    
    /// Properties when the attachment is a file.
    public struct FileProperty {
        public let path: String
        public let mime: String
        public let name: String
        public let inline: Bool
        
        /// Initilize a file property.
        ///
        /// - Parameters:
        ///   - path: File path.
        ///   - mime: MIME type of the file.
        ///   - name: File name which will be presented in the mail.
        ///   - inline: Whether the file could be inline or not. When set to
        ///             `true`, the attachment “Content-Disposition” header
        ///             will be `inline`, otherwise it will be `attachment`.
        public init(path: String, mime: String, name: String, inline: Bool) {
            self.path = path
            self.mime = mime
            self.name = name
            self.inline = inline
        }
    }
    
    /// Properties when the attachment is an HTML string.
    public struct HTMLProperty {
        public let content: String
        public let characterSet: String
        public let alternative: Bool
        
        /// Initilize an HTML property.
        ///
        /// - Parameters:
        ///   - content: Content of the HTML string.
        ///   - characterSet: Charater encoding set should be used.
        ///   - alternative: Whether this HTML could be alternative for plain
        ///     text.
        public init(content: String, characterSet: String, alternative: Bool) {
            self.content = content
            self.characterSet = characterSet
            self.alternative = alternative
        }
    }
    
    /// Properties when the attachment is some raw data.
    public struct DataProperty {
        public let data: Data
        public let mime: String
        public let name: String
        public let inline: Bool
        
        /// Initilize a file property.
        ///
        /// - Parameters:
        ///   - data: Data content.
        ///   - mime: MIME type of the file.
        ///   - name: File name which will be presented in the mail.
        ///   - inline: Whether the file could be inline or not. When set to
        ///             `true`, the attachment “Content-Disposition” header
        ///             will be `inline`, otherwise it will be `attachment`.
        public init(data: Data, mime: String, name: String, inline: Bool) {
            self.data = data
            self.mime = mime
            self.name = name
            self.inline = inline
        }
    }
}

extension Attachment {
    private var headersDictionary: [String: String] {
        var result = [String: String]()
        switch type {
            
        case .file(let fileProperty):
            result["CONTENT-TYPE"] = fileProperty.mime
            var attachmentDisposition = fileProperty.inline ? "inline" : "attachment"
            if let mime = fileProperty.name.mimeEncoded {
                attachmentDisposition.append("; filename=\"\(mime)\"")
            }
            result["CONTENT-DISPOSITION"] = attachmentDisposition

        case .html(let htmlProperty):
            result["CONTENT-TYPE"] = "text/html; charset=\(htmlProperty.characterSet)"
            
        case .data(let dataProperty):
            result["CONTENT-TYPE"] = dataProperty.mime
            var attachmentDisposition = dataProperty.inline ? "inline" : "attachment"
            if let mime = dataProperty.name.mimeEncoded {
                attachmentDisposition.append("; filename=\"\(mime)\"")
            }
            result["CONTENT-DISPOSITION"] = attachmentDisposition
        }
        
        result["CONTENT-TRANSFER-ENCODING"] = "BASE64"
        
        for (key, value) in additionalHeaders {
            result[key.uppercased()] = value
        }
        
        return result
    }
    
    var headers: String {
        return headersDictionary.map { (key, value) in
            return "\(key): \(value)"
            }.joined(separator: CRLF)
    }
}
