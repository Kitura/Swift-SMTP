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

#if os(Linux)
    import Dispatch
#endif

public typealias Progress = ((Mail, Error?) -> Void)?
public typealias Completion = (([Mail], [(Mail, Error)]) -> Void)?

class MailSender {
    private var socket: SMTPSocket
    private var mailsToSend: [Mail]
    private var progress: Progress
    private var completion: Completion
    private var sent = [Mail]()
    private var failed = [(Mail, Error)]()
    private var dataSender: DataSender

    init(socket: SMTPSocket,
         mailsToSend: [Mail],
         progress: Progress,
         completion: Completion) {
        self.socket = socket
        self.mailsToSend = mailsToSend
        self.progress = progress
        self.completion = completion
        dataSender = DataSender(socket: socket)
    }

    func send() {
        DispatchQueue.global().async {
            self.sendNext()
        }
    }
}

private extension MailSender {
    func sendNext() {
        if mailsToSend.isEmpty {
            completion?(sent, failed)
            progress = nil
            completion = nil
            try? quit()
            return
        }
        let mail = mailsToSend.removeFirst()
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
        DispatchQueue.global().async {
            self.sendNext()
        }
    }

    func quit() throws {
        try socket.send(.quit)
        socket.close()
    }
}

private extension MailSender {
    func send(_ mail: Mail) throws {
        let recipientEmails = try getRecipientEmails(from: mail)
        try validateEmails(recipientEmails)
        try sendMail(mail.from.email)
        try sendTo(recipientEmails)
        try data()
        try dataSender.send(mail)
        try dataEnd()
    }

    private func getRecipientEmails(from mail: Mail) throws -> [String] {
        var recipientEmails = mail.to.map { $0.email }
        recipientEmails += mail.cc.map { $0.email }
        recipientEmails += mail.bcc.map { $0.email }

        guard !recipientEmails.isEmpty else {
            throw SMTPError.noRecipients
        }

        return recipientEmails
    }

    private func validateEmails(_ emails: [String]) throws {
        for email in emails where try !email.isValidEmail() {
            throw SMTPError.invalidEmail(email: email)
        }
    }

    private func sendMail(_ from: String) throws {
        try socket.send(.mail(from))
    }

    private func sendTo(_ emails: [String]) throws {
        for email in emails {
            try socket.send(.rcpt(email))
        }
    }

    private func data() throws {
        try socket.send(.data)
    }

    private func dataEnd() throws {
        try socket.send(.dataEnd)
    }
}

#if os(Linux) && !swift(>=3.1)
    private typealias NSRegularExpression = RegularExpression
#endif

private extension NSRegularExpression {
    static let emailRegex = try? NSRegularExpression(
        pattern: "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}",
        options: []
    )
}

extension String {
    func isValidEmail() throws -> Bool {
        guard let emailRegex = NSRegularExpression.emailRegex else {
            throw SMTPError.createEmailRegexFailed
        }
        let range = NSRange(location: 0, length: count)
        return !emailRegex.matches(in: self, options: [], range: range).isEmpty
    }
}
