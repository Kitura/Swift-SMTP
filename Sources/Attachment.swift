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
public struct Attachment {
    let type: AttachmentType
    let additionalHeaders: [String: String]?
    let related: [Attachment]?
    
    var hasRelated: Bool {
        return related != nil
    }
    
    var isAlternative: Bool {
        if case .html(let p) = type, p.alternative {
            return true
        }
        return false
    }
    
    /// Initialize an attachment from a local file.
    ///
    /// - parameters:
    ///     - filePath: Path to the local file.
    ///     - mime: MIME type of the file. Default is 
    ///             "application/octet-stream".
    ///     - name: Name of the file. Defaults to the name component in its 
    ///             file path.
    ///     - inline: Indicates if attachment is inline. To embed the attachment 
    ///               in mail content, set to `true`. To send as standalone 
    ///               attachment, set to false. Defaults to `false`.
    ///     - additionalHeaders: Additional headers for the attachment. 
    ///                          (optional)
    ///     - related: Related attachments of this attachment. (optional)
    public init(filePath: String, mime: String = "application/octet-stream", name: String? = nil, inline: Bool = false, additionalHeaders: [String: String]? = nil, related: [Attachment]? = nil) {
        let name = name ?? NSString(string: filePath).lastPathComponent
        let fileProperty = FileProperty(path: filePath, mime: mime, name: name, inline: inline)
        self.init(type: .file(fileProperty), additionalHeaders: additionalHeaders, related: related)
    }
    
    /// Initialize an HTML attachment.
    ///
    /// - parameters:
    ///     - htmlContent: Content string of HTML.
    ///     - characterSet: Character encoding of `htmlContent`. Defaults to
    ///                     "utf-8".
    ///     - alternative: Whether the HTML is an alternative for plain text or 
    ///                    not. Defaults to `true`.
    ///     - additionalHeaders: Additional headers for the attachment.
    ///                          (optional)
    ///     - related: Related attachments of this attachment. (optional)
    public init(htmlContent: String, characterSet: String = "utf-8", alternative: Bool = true, additionalHeaders: [String: String]? = nil, related: [Attachment]? = nil) {
        let htmlProperty = HTMLProperty(content: htmlContent, characterSet: characterSet, alternative: alternative)
        self.init(type: .html(htmlProperty), additionalHeaders: additionalHeaders, related: related)
    }
    
    /// Initialize a data attachment.
    ///
    /// - parameters:
    ///     - data: Raw data to be sent as attachment.
    ///     - mime: MIME type of the data.
    ///     - name: File name which will be presented in the mail.
    ///     - inline: Indicates if attachment is inline. To embed the attachment
    ///               in mail content, set to `false`. To send as standalone
    ///               attachment, set to false. Defaults to `false`.
    ///     - additionalHeaders: Additional headers for the attachment.
    ///                          (optional)
    ///     - related: Related attachments of this attachment. (optional)
    public init(data: Data, mime: String, name: String, inline: Bool = false, additionalHeaders: [String: String]? = nil, related: [Attachment]? = nil) {
        let dataProperty = DataProperty(data: data, mime: mime, name: name, inline: inline)
        self.init(type: .data(dataProperty), additionalHeaders: additionalHeaders, related: related)
    }
    
    init(type: AttachmentType, additionalHeaders: [String: String]?, related: [Attachment]?) {
        self.type = type
        self.additionalHeaders = additionalHeaders
        self.related = related
    }
}

extension Attachment {
    enum AttachmentType {
        case file(FileProperty)
        case html(HTMLProperty)
        case data(DataProperty)
    }
    
    struct FileProperty {
        let path: String
        let mime: String
        let name: String
        let inline: Bool
        
        init(path: String, mime: String, name: String, inline: Bool) {
            self.path = path
            self.mime = mime
            self.name = name
            self.inline = inline
        }
    }
    
    struct HTMLProperty {
        let content: String
        let characterSet: String
        let alternative: Bool
        
        init(content: String, characterSet: String, alternative: Bool) {
            self.content = content
            self.characterSet = characterSet
            self.alternative = alternative
        }
    }
    
    struct DataProperty {
        let data: Data
        let mime: String
        let name: String
        let inline: Bool
        
        init(data: Data, mime: String, name: String, inline: Bool) {
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
            
        case .file(let file):
            result["CONTENT-TYPE"] = file.mime
            var attachmentDisposition = file.inline ? "inline" : "attachment"
            if let mime = file.name.mimeEncoded {
                attachmentDisposition.append("; filename=\"\(mime)\"")
            }
            result["CONTENT-DISPOSITION"] = attachmentDisposition
            
        case .html(let html):
            result["CONTENT-TYPE"] = "text/html; charset=\(html.characterSet)"
            result["CONTENT-DISPOSITION"] = "inline"
            
        case .data(let data):
            result["CONTENT-TYPE"] = data.mime
            var attachmentDisposition = data.inline ? "inline" : "attachment"
            if let mime = data.name.mimeEncoded {
                attachmentDisposition.append("; filename=\"\(mime)\"")
            }
            result["CONTENT-DISPOSITION"] = attachmentDisposition
        }
        
        result["CONTENT-TRANSFER-ENCODING"] = "BASE64"
        
        if let additionalHeaders = additionalHeaders {
            for (key, value) in additionalHeaders {
                result[key.uppercased()] = value
            }
        }
        
        return result
    }
    
    var headers: String {
        return headersDictionary.map { (key, value) in
            return "\(key): \(value)"
            }.joined(separator: CRLF)
    }
}
