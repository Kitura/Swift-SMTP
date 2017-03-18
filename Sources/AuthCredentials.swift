//
//  CryptoEncoder.swift
//  KituraSMTP
//
//  Created by Quan Vo on 3/8/17.
//
//

import Foundation
import Cryptor

struct AuthCredentials {
    static func cramMD5(challenge: String, user: String, password: String) throws -> String {
        guard let hmac = HMAC(using: HMAC.Algorithm.md5, key: password).update(string: try challenge.base64Decoded())?.final() else {
            throw SMTPError(.md5HashChallengeFail)
        }
        let digest = CryptoUtils.hexString(from: hmac)
        return ("\(user) \(digest)").base64Encoded
    }
    
    static func login(user: String, password: String) -> (encodedUser: String, encodedPassword: String) {
        return (user.base64Encoded, password.base64Encoded)
    }
    
    static func plain(user: String, password: String) -> String {
        let text = "\u{0000}\(user)\u{0000}\(password)"
        return text.base64Encoded
    }
    
    static func xoauth2(user: String, accessToken: String) -> String {
        let text = "user=\(user)\u{0001}auth=Bearer \(accessToken)\u{0001}\u{0001}"
        return text.base64Encoded
    }
}

private extension String {
    var base64Encoded: String {
        return Data(utf8).base64EncodedString()
    }
    
    func base64Decoded() throws -> String {
        guard let data = Data(base64Encoded: self), let base64Decoded = String(data: data, encoding: .utf8) else {
            throw SMTPError(.base64DecodeFail(self))
        }
        return base64Decoded
    }
}
