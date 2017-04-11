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
