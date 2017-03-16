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

class SMTPSend {
    fileprivate var socket: SMTPSocket
    private let login: SMTPLogin
    private let queue = DispatchQueue(label: "com.ibm.Kitura-SMTP.queue")
    private var pending = [Mail]()
    private var sent = [Mail]()
    private var failed = [(Mail, Error)]()
    private var isSending = false
    private var progress: ((Mail, Error?) -> Void)?
    private var completion: (([Mail], [(mail: Mail, error: Error)]) -> Void)?
    
    init(hostname: String, user: String, password: String, accessToken: String?, domainName: String, authMethods: [SMTP.AuthMethod], chainFilePath: String?, chainFilePassword: String?, selfSignedCerts: Bool?) throws {
        socket = try SMTPSocket()
        login = SMTPLogin(hostname: hostname, user: user, password: password, accessToken: accessToken, domainName: domainName, authMethods: authMethods, chainFilePath: chainFilePath, chainFilePassword: chainFilePassword, selfSignedCerts: selfSignedCerts, socket: socket)
    }
    
    func send(_ mail: Mail, completion: ((Error?) -> Void)? = nil) {
        send([mail]) { (_, failed) in
            if let err = failed.first?.1 {
                completion?(err)
            } else {
                completion?(nil)
            }
        }
    }
    
    func send(_ mails: [Mail], progress: ((Mail, Error?) -> Void)? = nil, completion: ((_ sent: [Mail], _ failed: [(mail: Mail, error: Error)]) -> Void)? = nil) {
        queue.async {
            if self.isSending { return }
            
            self.isSending = true
            self.pending = mails
            self.progress = progress
            self.completion = completion
            do {
                self.socket = try self.login.login()
            } catch {
                self.isSending = false
                completion?([], self.pending.map({ ($0, error) }))
                return
            }
            
            self.send()
        }
    }
    
    private func send() {
        if pending.isEmpty {
            try? quit()
            isSending = false
            completion?(sent, failed)
            progress = nil
            completion = nil
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
        
        queue.async { self.send() }
    }
    
    private func send(_ mail: Mail) throws {
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
}

private extension SMTPSend {
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
        defer { socket.socket.close() }
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
