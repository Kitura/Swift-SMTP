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

let timeout: Double = 30

// NOTE: 
// Sending too many emails from one account may suspend it for some time.
// Use different emails when testing extensively.

let slSMTP = "smtp.socketlabs.com"
let slUser = "server16337"
let slPassword = "w5DRd9c2EPo6f8NQa4"
let slMail = "quan.vo@ibm.com"

let gSMTP = "smtp.gmail.com"
let gMail = "kiturasmtp@gmail.com"
let gMail2 = "kiturasmtp2@gmail.com"
let gPassword = "ibm12345"
let gSecure = true

let smtp = SMTP(hostname: slSMTP, user: slUser, password: slPassword, secure: false)

let from = User(name: "Dr. Light", email: slMail)
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
