//
//  SMTPSend.swift
//  KituraSMTP
//
//  Created by Quan Vo on 3/16/17.
//
//

import Foundation
import Socket

#if os(Linux)
    import Dispatch
#endif

typealias Progress = ((Mail, Error?) -> Void)?
typealias Completion = (([Mail], [(mail: Mail, error: Error)]) -> Void)?

class SMTPSender {
    fileprivate var socket: SMTPSocket
    fileprivate var config: SMTPConfig
    fileprivate var pending: [Mail]
    fileprivate var progress: Progress
    fileprivate var completion: Completion
    fileprivate let queue = DispatchQueue(label: "com.ibm.Kitura-SMTP.queue")
    fileprivate var sent = [Mail]()
    fileprivate var failed = [(Mail, Error)]()
    
    init(config: SMTPConfig, pending: [Mail], progress: Progress, completion: Completion) throws {
        socket = try SMTPSocket()
        self.config = config
        self.pending = pending
        self.progress = progress
        self.completion = completion
    }
    
    func resume() {
        queue.async {
            do {
                self.socket = try SMTPLogin(config: self.config, socket: self.socket).login()
            } catch {
                self.completion?([], self.pending.map { ($0, error) })
                self.socket.close()
                self.cleanUp()
                return
            }
            self.sendNext()
        }
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
    
    private func send(_ mail: Mail) throws {
        try SMTPSender.validateEmails(mail.to.map { $0.email })
        try sendMail(mail.from.email)
        try sendTo(mail.to[0].email)
        try data()
        
        if let name = mail.from.name { try socket.write("From: \(name) <\(mail.from.email)>") }
        else { try socket.write("From: <\(mail.from.email)>") }
        
        if let name = mail.to[0].name { try socket.write("To: \(name) <\(mail.to[0].email)>") }
        else { try socket.write("To: <\(mail.to[0].email)>") }
        
        let date = Date().toString()
        try socket.write("Date: \(date)")
        
        try socket.write("Subject: \(mail.subject)")
        try socket.write("")
        try socket.write("\(mail.text)")
        try dataEnd()
    }
    
    func cleanUp() {
        progress = nil
        completion = nil
    }
}

private extension SMTPSender {
    private static let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
    private static let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
    
    static func validateEmails(_ emails: [String]) throws {
        for email in emails {
            guard emailTest.evaluate(with: email) else {
                throw SMTPError.invalidEmail(email)
            }
        }
    }
    
    func sendMail(_ from: String) throws {
        return try socket.send(.mail(from))
    }
    
    func sendTo(_ to: String) throws {
        return try socket.send(.rcpt(to))
    }
    
    func data() throws {
        return try socket.send(.data)
    }
    
    func dataEnd() throws {
        return try socket.send(.dataEnd)
    }
    
    func quit() throws {
        defer { socket.close() }
        return try socket.send(.quit)
    }
}

private extension DateFormatter {
    static let smtpDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, d MMM yyyy HH:mm:ss ZZZ"
        return formatter
    }()
}

private extension Date {
    func toString() -> String {
        return DateFormatter.smtpDateFormatter.string(from: self)
    }
}
