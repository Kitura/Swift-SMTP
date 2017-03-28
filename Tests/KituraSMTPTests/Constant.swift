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

let timeout: Double = 10

// NOTE: 
// Sending too many emails from one account will suspend it for some time.
// Use different emails when testing extensively.

let gmailSMTP = "smtp.gmail.com"
let email1 = "kiturasmtp4@gmail.com"
let email2 = "kiturasmtp@gmail.com"
let password = "ibm12345"

let smtp = SMTP(hostname: gmailSMTP, user: email1, password: password)

let user = User(email: email1)
let from = User(name: "Dr. Light", email: email1)
let to1 = User(name: "Megaman", email: email1)
let to2 = User(name: "Roll", email: email2)

let text = "Humans and robots living together in harmony and equality. That was my ultimate wish."
let html = "<html><img src=\"http://vignette2.wikia.nocookie.net/megaman/images/4/40/StH250RobotMasters.jpg/revision/latest?cb=20130711161323\"/></html>"
let imgFilePath = #file
    .characters
    .split(separator: "/", omittingEmptySubsequences: false)
    .dropLast(1)
    .map { String($0) }
    .joined(separator: "/") + "/x.png"
