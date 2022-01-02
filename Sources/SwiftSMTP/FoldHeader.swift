/**
 * Copyright Stephen Beitzel 2021
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

/// This extension is intended to encapsulate the wrap/unwrap
/// functionality described at https://datatracker.ietf.org/doc/html/rfc5322#section-2.2.3

extension String {

    /// Given the desired line length, split this string into
    /// a sequence of lines of nearly that length, then join them
    /// back together with the sequence `\r\n `
    public func wrap(_ to: Int = 78) -> String {
        /*
         The RFC says that we should try to wrap lines at logical separator
         tokens, such as the comma-space separating email addresses or the
         whitespace separating words, but that it is not actually required.
         This implementation just splits at the suggested length, without
         trying to be smart about tokens, since we don't know what the tokens
         might be in a given string.
         */
        var lines: [String] = []
        var workingString = self
        while workingString.count > to {
            lines.append(String(workingString.prefix(to)))
            let sliceIndex = workingString.index(startIndex, offsetBy: to)
            workingString = String(workingString.suffix(from: sliceIndex))
        }
        lines.append(workingString)
        return lines.joined(separator: "\r\n ")
    }

    /// Find all occurrences of CRLF followed by a whitespace and
    /// replace them with an empty string.
    public func unwrap() -> String {
        let regex = try! NSRegularExpression(pattern: "\r\n\\s", options: [])
        let range = NSMakeRange(0, count)
        let modString = regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "")
        return modString
    }
}