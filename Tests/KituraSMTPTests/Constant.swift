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

import KituraSMTP

#if os(Linux)
    import Glibc
#else
    import Foundation
#endif

let testDuration: Double = 20

let hostname = "smtp.gmail.com"
let user = "kiturasmtp" + Int.randomEmailNum(4) + "@gmail.com"
let user2 = "kiturasmtp@gmail.com"
let password = "ibm12345"
let port = Ports.tls.rawValue
let secure = true
let authMethods: [AuthMethod] = [.cramMD5, .login, .plain, .xoauth2]
let domainName = "localhost"
let timeout = 10

let root = #file
    .characters
    .split(separator: "/", omittingEmptySubsequences: false)
    .dropLast(1)
    .map { String($0) }
    .joined(separator: "/")

#if os(Linux)
    let cert = root + "/cert.pem"
    let key = root + "/key.pem"
    let ssl = SSL(withCACertificateDirectory: nil, usingCertificateFile: cert, withKeyFile: key)
#else
    let cert = root + "/cert.pfx"
    let certPassword = "kitura"
    let ssl = SSL(withChainFilePath: cert, withPassword: certPassword)
#endif

let smtp = SMTP(hostname: hostname, user: user, password: password, ssl: ssl)
let from = User(name: "Dr. Light", email: user)
let to = User(name: "Megaman", email: user2)
let to2 = User(name: "Roll", email: "kiturasmtp2@gmail.com")
let text = "Humans and robots living together in harmony and equality. That was my ultimate wish."
let html = "<html><img src=\"http://vignette2.wikia.nocookie.net/megaman/images/4/40/StH250RobotMasters.jpg/revision/latest?cb=20130711161323\"/></html>"
let imgFilePath = root + "/x.png"
let data = "{\"key\": \"hello world\"}".data(using: .utf8)!

// https://www.base64decode.org/
let randomText1 = "Picture removal detract earnest is by. Esteems met joy attempt way clothes yet demesne tedious. Replying an marianne do it an entrance advanced. Two dare say play when hold. Required bringing me material stanhill jointure is as he. Mutual indeed yet her living result matter him bed whence."
let randomText1Encoded = "UGljdHVyZSByZW1vdmFsIGRldHJhY3QgZWFybmVzdCBpcyBieS4gRXN0ZWVtcyBtZXQgam95IGF0dGVtcHQgd2F5IGNsb3RoZXMgeWV0IGRlbWVzbmUgdGVkaW91cy4gUmVwbHlpbmcgYW4gbWFyaWFubmUgZG8gaXQgYW4gZW50cmFuY2UgYWR2YW5jZWQuIFR3byBkYXJlIHNheSBwbGF5IHdoZW4gaG9sZC4gUmVxdWlyZWQgYnJpbmdpbmcgbWUgbWF0ZXJpYWwgc3RhbmhpbGwgam9pbnR1cmUgaXMgYXMgaGUuIE11dHVhbCBpbmRlZWQgeWV0IGhlciBsaXZpbmcgcmVzdWx0IG1hdHRlciBoaW0gYmVkIHdoZW5jZS4="
let randomText2 = "Brillo viento gas esa contar hay. Alla no toda lune faro daba en pero. Ir rumiar altura id venian. El robusto hablado ya diarios tu hacerla mermado. Las sus renunciaba llamaradas misteriosa doscientas favorcillo dos pie. Una era fue pedirselos periodicos doscientas actualidad con. Exigian un en oh algunos adivino parezca notario yo. Eres oro dos mal lune vivo sepa les seda. Tio energia una esa abultar por tufillo sirenas persona suspiro. Me pandero tardaba pedirme puertas so senales la."
let randomText2Encoded = "QnJpbGxvIHZpZW50byBnYXMgZXNhIGNvbnRhciBoYXkuIEFsbGEgbm8gdG9kYSBsdW5lIGZhcm8gZGFiYSBlbiBwZXJvLiBJciBydW1pYXIgYWx0dXJhIGlkIHZlbmlhbi4gRWwgcm9idXN0byBoYWJsYWRvIHlhIGRpYXJpb3MgdHUgaGFjZXJsYSBtZXJtYWRvLiBMYXMgc3VzIHJlbnVuY2lhYmEgbGxhbWFyYWRhcyBtaXN0ZXJpb3NhIGRvc2NpZW50YXMgZmF2b3JjaWxsbyBkb3MgcGllLiBVbmEgZXJhIGZ1ZSBwZWRpcnNlbG9zIHBlcmlvZGljb3MgZG9zY2llbnRhcyBhY3R1YWxpZGFkIGNvbi4gRXhpZ2lhbiB1biBlbiBvaCBhbGd1bm9zIGFkaXZpbm8gcGFyZXpjYSBub3RhcmlvIHlvLiBFcmVzIG9ybyBkb3MgbWFsIGx1bmUgdml2byBzZXBhIGxlcyBzZWRhLiBUaW8gZW5lcmdpYSB1bmEgZXNhIGFidWx0YXIgcG9yIHR1ZmlsbG8gc2lyZW5hcyBwZXJzb25hIHN1c3Bpcm8uIE1lIHBhbmRlcm8gdGFyZGFiYSBwZWRpcm1lIHB1ZXJ0YXMgc28gc2VuYWxlcyBsYS4="
let randomText3 = "Intueor veritas suo majoris attinet rem res aggredi similia mei. Disputari abducerem ob ex ha interitum conflatos concipiam. Curam plura aequo rem etc serio fecto caput. Ea posterum lectorem remanere experiar videamus gi cognitum vi. Ad invenit accepit to petitis ea usitata ad. Hoc nam quibus hos oculis cumque videam ita. Res cau infinitum quadratam sanguinem."
let randomText3Encoded = "SW50dWVvciB2ZXJpdGFzIHN1byBtYWpvcmlzIGF0dGluZXQgcmVtIHJlcyBhZ2dyZWRpIHNpbWlsaWEgbWVpLiBEaXNwdXRhcmkgYWJkdWNlcmVtIG9iIGV4IGhhIGludGVyaXR1bSBjb25mbGF0b3MgY29uY2lwaWFtLiBDdXJhbSBwbHVyYSBhZXF1byByZW0gZXRjIHNlcmlvIGZlY3RvIGNhcHV0LiBFYSBwb3N0ZXJ1bSBsZWN0b3JlbSByZW1hbmVyZSBleHBlcmlhciB2aWRlYW11cyBnaSBjb2duaXR1bSB2aS4gQWQgaW52ZW5pdCBhY2NlcGl0IHRvIHBldGl0aXMgZWEgdXNpdGF0YSBhZC4gSG9jIG5hbSBxdWlidXMgaG9zIG9jdWxpcyBjdW1xdWUgdmlkZWFtIGl0YS4gUmVzIGNhdSBpbmZpbml0dW0gcXVhZHJhdGFtIHNhbmd1aW5lbS4="

private extension Int {
    static func randomEmailNum(_ max: Int) -> String {
        #if os(Linux)
            srand(UInt32(time(nil)))
            let r = Int(random() % max)
        #else
            let r = Int(arc4random_uniform(UInt32(max)))
        #endif
        if r == 0 { return "" }
        return String(r)
    }
}
