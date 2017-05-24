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

class Sender {
    var socket: SMTPSocket
    var pending: [Mail]
    var progress: Progress
    var completion: Completion
    let queue = DispatchQueue(label: "com.ibm.Kitura-SMTP.Sender.queue")
    var sent = [Mail]()
    var failed = [(Mail, Error)]()
    var dataSender: DataSender

    init(socket: SMTPSocket, pending: [Mail], progress: Progress, completion: Completion) {
        self.socket = socket
        self.pending = pending
        self.progress = progress
        self.completion = completion
        dataSender = DataSender(socket: socket)
    }

    func send() {
        queue.async { self.sendNext() }
    }
}

private extension Sender {
    func sendNext() {
        if pending.isEmpty {
            completion?(sent, failed)
            progress = nil
            completion = nil
            try? quit()
            return
        }

        let mail = pending.removeFirst()

        do {
            try send(mail)
            if completion != nil {
                sent.append(mail)
            }
            progress?(mail, nil)

        } catch {
            if completion != nil {
                failed.append((mail, error))
            }
            progress?(mail, error)
        }

        queue.async { self.sendNext() }
    }

    func quit() throws {
        let _: Void = try socket.send(.quit)
        socket.close()
    }
}

private extension Sender {
    func send(_ mail: Mail) throws {
        let recipientEmails = getRecipientEmails(from: mail)
        try validateEmails(recipientEmails)
        try sendMail(mail.from.email)
        try sendTo(recipientEmails)
        try data()
        try dataSender.send(mail)
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
        for email in emails where try !email.isValidEmail() {
            throw SMTPError(.invalidEmail(email))
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

#if os(Linux) && !swift(>=3.1)
    private typealias Regex = RegularExpression
#else
    private typealias Regex = NSRegularExpression
#endif

private extension Regex {
    static let emailRegex = try? Regex(pattern: "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}", options: [])
}

extension String {
    func isValidEmail() throws -> Bool {
        guard let emailRegex = Regex.emailRegex else {
            throw SMTPError(.createEmailRegexFailed)
        }
        let range = NSRange(location: 0, length: utf16.count)
        return !emailRegex.matches(in: self, options: [], range: range).isEmpty
    }
}
