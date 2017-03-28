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
import Socket

#if os(Linux)
    import Dispatch
#endif

public typealias Progress = ((Mail, Error?) -> Void)?
public typealias Completion = (([Mail], [(Mail, Error)]) -> Void)?

class SMTPSender {
    fileprivate var socket: SMTPSocket
    fileprivate var pending: [Mail]
    fileprivate var progress: Progress
    fileprivate var completion: Completion
    fileprivate let queue = DispatchQueue(label: "com.ibm.Kitura-SMTP.SMTPSenderQueue")
    fileprivate var sent = [Mail]()
    fileprivate var failed = [(Mail, Error)]()
    
    init(socket: SMTPSocket, pending: [Mail], progress: Progress, completion: Completion) throws {
        self.socket = socket
        self.pending = pending
        self.progress = progress
        self.completion = completion
    }
    
    func resume() {
        queue.async { self.sendNext() }
    }
    
    deinit {
        socket.close()
    }
}

private extension SMTPSender {
    func sendNext() {
        if pending.isEmpty {
            completion?(sent, failed)
            try? quit()
            cleanUp()
            return
        }
        
        let mail = pending.removeFirst()
        
        do {
            try send(mail)
            sent.append(mail)
            progress?(mail, nil)
            
        } catch {
            failed.append((mail, error))
            progress?(mail, error)
        }
        
        queue.async { self.sendNext() }
    }
    
    func cleanUp() {
        progress = nil
        completion = nil
    }
    
    func quit() throws {
        defer { socket.close() }
        return try socket.send(.quit)
    }
}

private extension SMTPSender {
    func send(_ mail: Mail) throws {
        let recipientEmails = getRecipientEmails(from: mail)
        try validateEmails(recipientEmails)
        try sendMail(mail.from.email)
        try sendTo(recipientEmails)
        try data()
        try SMTPDataSender(mail: mail, socket: socket).send()
        try dataEnd()
    }
    
    private func getRecipientEmails(from mail: Mail) -> [String] {
        var recipientEmails = mail.to.map { $0.email }
        if let cc = mail.cc {
            recipientEmails += cc.map { $0.email }
        }
        if let bcc = mail.bcc {
            recipientEmails += bcc.map { $0.email }
        }
        return recipientEmails
    }
    
    private func validateEmails(_ emails: [String]) throws {
        for email in emails {
            if !email.isValidEmail {
                throw SMTPError(.invalidEmail(email))
            }
        }
    }
    
    private func sendMail(_ from: String) throws {
        return try socket.send(.mail(from))
    }
    
    private func sendTo(_ emails: [String]) throws {
        for email in emails {
            let _: Void = try socket.send(.rcpt(email))
        }
    }
    
    private func data() throws {
        return try socket.send(.data)
    }
    
    private func dataEnd() throws {
        return try socket.send(.dataEnd)
    }
}

#if os(Linux)
    private typealias Regex = RegularExpression
#else
    private typealias Regex = NSRegularExpression
#endif

private extension Regex {
    static let emailRegex = try! Regex(pattern: "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}", options: [])
}

private extension String {
    var isValidEmail: Bool {
        let range = NSMakeRange(0, utf16.count)
        return !Regex.emailRegex.matches(in: self, options: [], range: range).isEmpty
    }
}
