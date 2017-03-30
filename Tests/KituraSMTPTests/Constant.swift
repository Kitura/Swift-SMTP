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
import KituraSMTP

#if os(Linux)
    import Glibc
#endif

let timeout: Double = 20

// NOTE:
// Sending too many emails from one account may suspend it for some time.
// Use different emails when testing extensively.

let gSMTP = "smtp.gmail.com"
let gMail = "kiturasmtp" + "\(Int.randomEmailNum(4))" + "@gmail.com"
let gMail2 = "kiturasmtp@gmail.com"
let gPassword = "ibm12345"  

let smtp = SMTP(hostname: gSMTP, user: gMail, password: gPassword)

let from = User(name: "Dr. Light", email: gMail)
let to = User(name: "Megaman", email: gMail)
let to2 = User(name: "Roll", email: gMail2)

let text = "Humans and robots living together in harmony and equality. That was my ultimate wish."
let html = "<html><img src=\"http://vignette2.wikia.nocookie.net/megaman/images/4/40/StH250RobotMasters.jpg/revision/latest?cb=20130711161323\"/></html>"
let imgFilePath = #file
    .characters
    .split(separator: "/", omittingEmptySubsequences: false)
    .dropLast(1)
    .map { String($0) }
    .joined(separator: "/") + "/x.png"

private extension Int {
    static func randomEmailNum(_ max: Int) -> String {
        var r: Int
        #if os(Linux)
            srand(UInt32(time(nil)))
            r = Int(random() % 3) + 1
        #else
            r = Int(arc4random_uniform(UInt32(3)) + 1)
        #endif
        if r == 0 { return "" }
        return String(r)
    }
}
