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
let hostname = "smtp.gmail.com"
let myEmail: String? = nil
let myPassword: String? = nil
let port: Int32 = 587
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

let randomText1Encoded = randomText1.data(using: .utf8)!.base64EncodedString(options: .lineLength76Characters)

let randomText2 = "Brillo viento gas esa contar hay. Alla no toda lune faro daba en pero. Ir rumiar altura id venian. El robusto hablado ya diarios tu hacerla mermado. Las sus renunciaba llamaradas misteriosa doscientas favorcillo dos pie. Una era fue pedirselos periodicos doscientas actualidad con. Exigian un en oh algunos adivino parezca notario yo. Eres oro dos mal lune vivo sepa les seda. Tio energia una esa abultar por tufillo sirenas persona suspiro. Me pandero tardaba pedirme puertas so senales la."

let randomText2Encoded = randomText2.data(using: .utf8)!.base64EncodedString(options: .lineLength76Characters)

let randomText3 = "Intueor veritas suo majoris attinet rem res aggredi similia mei. Disputari abducerem ob ex ha interitum conflatos concipiam. Curam plura aequo rem etc serio fecto caput. Ea posterum lectorem remanere experiar videamus gi cognitum vi. Ad invenit accepit to petitis ea usitata ad. Hoc nam quibus hos oculis cumque videam ita. Res cau infinitum quadratam sanguinem."

let randomText3Encoded = randomText3.data(using: .utf8)!.base64EncodedString(options: .lineLength76Characters)

