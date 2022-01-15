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

import SwiftSMTP
import Foundation

#if os(Linux)
    import Glibc
#endif

let testDuration: Double = 15

// 📧📧📧 Fill in your own SMTP login info for local testing
// ⚠️⚠️⚠️ DO NOT CHECK IN YOUR EMAIL CREDENTALS!!!
let noAuthHost: String? = "localhost"
let noAuthPort: Int32 = 1081

let hostname = "mail.kitura.dev"
let myEmail: String? = "tester@local"
let myPassword: String? = nil
let portTLS: Int32 = 465
let portPlain: Int32 = 2525
let authMethods: [String: AuthMethod] = [
    AuthMethod.cramMD5.rawValue: .cramMD5,
    AuthMethod.login.rawValue: .login,
    AuthMethod.plain.rawValue: .plain
]
let domainName = "localhost"
let timeout: UInt = 10

let email: String = {
    if let email = myEmail {
        return email
    }
    guard let email = ProcessInfo.processInfo.environment["EMAIL"] else {
        fatalError("Please provide email credentials for local testing.")
    }
    return email
}()

let password: String = {
    if let password = myPassword {
        return password
    }
    guard let password = ProcessInfo.processInfo.environment["PASSWORD"] else {
        fatalError("Please provide email credentials for local testing.")
    }
    return password
}()

let senderEmailDomain: String = {
#if swift(>=5)
    if let atIndex = email.firstIndex(of: "@") {
        let domainStart = email.index(after: atIndex)
        return String(email[domainStart...])
    } else {
        return "gmail.com"
    }
#else
    if let atIndex = email.index(of: "@") {
        let domainStart = email.index(after: atIndex)
        return String(email[domainStart...])
    } else {
        return "gmail.com"
    }
#endif
}()

let testsDir: String = {
    return URL(fileURLWithPath: #file).appendingPathComponent("..").standardized.path
}()

#if os(Linux)
let cert = testsDir + "/cert.pem"
let key = testsDir + "/key.pem"
let tlsConfiguration = TLSConfiguration(withCACertificateDirectory: nil, usingCertificateFile: cert, withKeyFile: key)
#else
let cert = testsDir + "/cert.pfx"
let certPassword = "kitura"
let tlsConfiguration = TLSConfiguration(withChainFilePath: cert, withPassword: certPassword)
#endif

let smtp = SMTP(hostname: hostname, email: email, password: password)
let from = Mail.User(name: "Dr. Light", email: email)
let to = Mail.User(name: "Megaman", email: email)
let to2 = Mail.User(name: "Roll", email: email)
let text = "Humans and robots living together in harmony and equality: That was my ultimate wish."
let html = "<html><img src=\"http://vignette2.wikia.nocookie.net/megaman/images/4/40/StH250RobotMasters.jpg/revision/latest?cb=20130711161323\"/></html>"
let imgFilePath = testsDir + "/x.png"
let data = "{\"key\": \"hello world\"}".data(using: .utf8)!

let validMessageIdMsg = "Valid Message-Id header found"
let invalidMessageIdMsg = "Message-Id header missing or invalid"
let multipleMessageIdsMsg = "More than one Message-Id header found"

// https://www.base64decode.org/
let randomText1 = "Picture removal detract earnest is by. Esteems met joy attempt way clothes yet demesne tedious. Replying an marianne do it an entrance advanced. Two dare say play when hold. Required bringing me material stanhill jointure is as he. Mutual indeed yet her living result matter him bed whence."

let randomText1Encoded = "UGljdHVyZSByZW1vdmFsIGRldHJhY3QgZWFybmVzdCBpcyBieS4gRXN0ZWVtcyBtZXQgam95IGF0dGVtcHQgd2F5IGNsb3RoZXMgeWV0IGRlbWVzbmUgdGVkaW91cy4gUmVwbHlpbmcgYW4gbWFyaWFubmUgZG8gaXQgYW4gZW50cmFuY2UgYWR2YW5jZWQuIFR3byBkYXJlIHNheSBwbGF5IHdoZW4gaG9sZC4gUmVxdWlyZWQgYnJpbmdpbmcgbWUgbWF0ZXJpYWwgc3RhbmhpbGwgam9pbnR1cmUgaXMgYXMgaGUuIE11dHVhbCBpbmRlZWQgeWV0IGhlciBsaXZpbmcgcmVzdWx0IG1hdHRlciBoaW0gYmVkIHdoZW5jZS4="
let randomText1EncodedWithLineLimit = """
    UGljdHVyZSByZW1vdmFsIGRldHJhY3QgZWFybmVzdCBpcyBieS4gRXN0ZWVtcyBtZXQgam95IGF0
    dGVtcHQgd2F5IGNsb3RoZXMgeWV0IGRlbWVzbmUgdGVkaW91cy4gUmVwbHlpbmcgYW4gbWFyaWFu
    bmUgZG8gaXQgYW4gZW50cmFuY2UgYWR2YW5jZWQuIFR3byBkYXJlIHNheSBwbGF5IHdoZW4gaG9s
    ZC4gUmVxdWlyZWQgYnJpbmdpbmcgbWUgbWF0ZXJpYWwgc3RhbmhpbGwgam9pbnR1cmUgaXMgYXMg
    aGUuIE11dHVhbCBpbmRlZWQgeWV0IGhlciBsaXZpbmcgcmVzdWx0IG1hdHRlciBoaW0gYmVkIHdo
    ZW5jZS4=
    """.replacingOccurrences(of: "\n", with: "\r\n")

let randomText2 = "Brillo viento gas esa contar hay. Alla no toda lune faro daba en pero. Ir rumiar altura id venian. El robusto hablado ya diarios tu hacerla mermado. Las sus renunciaba llamaradas misteriosa doscientas favorcillo dos pie. Una era fue pedirselos periodicos doscientas actualidad con. Exigian un en oh algunos adivino parezca notario yo. Eres oro dos mal lune vivo sepa les seda. Tio energia una esa abultar por tufillo sirenas persona suspiro. Me pandero tardaba pedirme puertas so senales la."

let randomText2Encoded = "QnJpbGxvIHZpZW50byBnYXMgZXNhIGNvbnRhciBoYXkuIEFsbGEgbm8gdG9kYSBsdW5lIGZhcm8gZGFiYSBlbiBwZXJvLiBJciBydW1pYXIgYWx0dXJhIGlkIHZlbmlhbi4gRWwgcm9idXN0byBoYWJsYWRvIHlhIGRpYXJpb3MgdHUgaGFjZXJsYSBtZXJtYWRvLiBMYXMgc3VzIHJlbnVuY2lhYmEgbGxhbWFyYWRhcyBtaXN0ZXJpb3NhIGRvc2NpZW50YXMgZmF2b3JjaWxsbyBkb3MgcGllLiBVbmEgZXJhIGZ1ZSBwZWRpcnNlbG9zIHBlcmlvZGljb3MgZG9zY2llbnRhcyBhY3R1YWxpZGFkIGNvbi4gRXhpZ2lhbiB1biBlbiBvaCBhbGd1bm9zIGFkaXZpbm8gcGFyZXpjYSBub3RhcmlvIHlvLiBFcmVzIG9ybyBkb3MgbWFsIGx1bmUgdml2byBzZXBhIGxlcyBzZWRhLiBUaW8gZW5lcmdpYSB1bmEgZXNhIGFidWx0YXIgcG9yIHR1ZmlsbG8gc2lyZW5hcyBwZXJzb25hIHN1c3Bpcm8uIE1lIHBhbmRlcm8gdGFyZGFiYSBwZWRpcm1lIHB1ZXJ0YXMgc28gc2VuYWxlcyBsYS4="
let randomText2EncodedWithLineLimit = """
    QnJpbGxvIHZpZW50byBnYXMgZXNhIGNvbnRhciBoYXkuIEFsbGEgbm8gdG9kYSBsdW5lIGZhcm8g
    ZGFiYSBlbiBwZXJvLiBJciBydW1pYXIgYWx0dXJhIGlkIHZlbmlhbi4gRWwgcm9idXN0byBoYWJs
    YWRvIHlhIGRpYXJpb3MgdHUgaGFjZXJsYSBtZXJtYWRvLiBMYXMgc3VzIHJlbnVuY2lhYmEgbGxh
    bWFyYWRhcyBtaXN0ZXJpb3NhIGRvc2NpZW50YXMgZmF2b3JjaWxsbyBkb3MgcGllLiBVbmEgZXJh
    IGZ1ZSBwZWRpcnNlbG9zIHBlcmlvZGljb3MgZG9zY2llbnRhcyBhY3R1YWxpZGFkIGNvbi4gRXhp
    Z2lhbiB1biBlbiBvaCBhbGd1bm9zIGFkaXZpbm8gcGFyZXpjYSBub3RhcmlvIHlvLiBFcmVzIG9y
    byBkb3MgbWFsIGx1bmUgdml2byBzZXBhIGxlcyBzZWRhLiBUaW8gZW5lcmdpYSB1bmEgZXNhIGFi
    dWx0YXIgcG9yIHR1ZmlsbG8gc2lyZW5hcyBwZXJzb25hIHN1c3Bpcm8uIE1lIHBhbmRlcm8gdGFy
    ZGFiYSBwZWRpcm1lIHB1ZXJ0YXMgc28gc2VuYWxlcyBsYS4=
    """.replacingOccurrences(of: "\n", with: "\r\n")

let randomText3 = "Intueor veritas suo majoris attinet rem res aggredi similia mei. Disputari abducerem ob ex ha interitum conflatos concipiam. Curam plura aequo rem etc serio fecto caput. Ea posterum lectorem remanere experiar videamus gi cognitum vi. Ad invenit accepit to petitis ea usitata ad. Hoc nam quibus hos oculis cumque videam ita. Res cau infinitum quadratam sanguinem."

let randomText3Encoded = "SW50dWVvciB2ZXJpdGFzIHN1byBtYWpvcmlzIGF0dGluZXQgcmVtIHJlcyBhZ2dyZWRpIHNpbWlsaWEgbWVpLiBEaXNwdXRhcmkgYWJkdWNlcmVtIG9iIGV4IGhhIGludGVyaXR1bSBjb25mbGF0b3MgY29uY2lwaWFtLiBDdXJhbSBwbHVyYSBhZXF1byByZW0gZXRjIHNlcmlvIGZlY3RvIGNhcHV0LiBFYSBwb3N0ZXJ1bSBsZWN0b3JlbSByZW1hbmVyZSBleHBlcmlhciB2aWRlYW11cyBnaSBjb2duaXR1bSB2aS4gQWQgaW52ZW5pdCBhY2NlcGl0IHRvIHBldGl0aXMgZWEgdXNpdGF0YSBhZC4gSG9jIG5hbSBxdWlidXMgaG9zIG9jdWxpcyBjdW1xdWUgdmlkZWFtIGl0YS4gUmVzIGNhdSBpbmZpbml0dW0gcXVhZHJhdGFtIHNhbmd1aW5lbS4="
let randomText3EncodedWithLineLimit = """
    SW50dWVvciB2ZXJpdGFzIHN1byBtYWpvcmlzIGF0dGluZXQgcmVtIHJlcyBhZ2dyZWRpIHNpbWls
    aWEgbWVpLiBEaXNwdXRhcmkgYWJkdWNlcmVtIG9iIGV4IGhhIGludGVyaXR1bSBjb25mbGF0b3Mg
    Y29uY2lwaWFtLiBDdXJhbSBwbHVyYSBhZXF1byByZW0gZXRjIHNlcmlvIGZlY3RvIGNhcHV0LiBF
    YSBwb3N0ZXJ1bSBsZWN0b3JlbSByZW1hbmVyZSBleHBlcmlhciB2aWRlYW11cyBnaSBjb2duaXR1
    bSB2aS4gQWQgaW52ZW5pdCBhY2NlcGl0IHRvIHBldGl0aXMgZWEgdXNpdGF0YSBhZC4gSG9jIG5h
    bSBxdWlidXMgaG9zIG9jdWxpcyBjdW1xdWUgdmlkZWFtIGl0YS4gUmVzIGNhdSBpbmZpbml0dW0g
    cXVhZHJhdGFtIHNhbmd1aW5lbS4=
    """.replacingOccurrences(of: "\n", with: "\r\n")
