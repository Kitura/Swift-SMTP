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
import Socket
import LoggerAPI

struct SMTPSocket {
    let socket: Socket
    
    init() throws {
        socket = try Socket.create()
    }
    
    func send(_ command: SMTPCommand) throws {
        try write(command.text)
        _ = try SMTPSocket.parseResponses(try readFromSocket(), command: command)
    }
    
    func send(_ command: SMTPCommand) throws -> SMTPResponse {
        try write(command.text)
        return try SMTPSocket.parseResponses(try readFromSocket(), command: command)[0]
    }
    
    func send(_ command: SMTPCommand) throws -> [SMTPResponse] {
        try write(command.text)
        return try SMTPSocket.parseResponses(try readFromSocket(), command: command)
    }
    
    func write(_ commandText: String) throws {
        Log.debug("[Kitura-SMTP c]: \(commandText)")
        _ = try socket.write(from: commandText + CRLF)
    }
    
    func write(_ data: Data) throws {
        Log.debug("[Kitura-SMTP c]: (sending data)")
        _ = try socket.write(from: data)
    }
    
    func readFromSocket() throws -> String {
        var buf = Data()
        _ = try socket.read(into: &buf)
        guard let res = String(data: buf, encoding: .utf8) else {
            throw SMTPError(.convertDataUTF8Fail(buf))
        }
        Log.debug("[Kitura-SMTP s]: \(res)")
        return res
    }
    
    static func parseResponses(_ responses: String, command: SMTPCommand) throws -> [SMTPResponse] {
        var validResponses = [SMTPResponse]()
        let resArr = responses.components(separatedBy: CRLF)
        for res in resArr {
            if res == "" { break }
            validResponses.append(SMTPResponse(code: try getResponseCode(res, command: command), message: getResponseMessage(res), response: res))
        }
        return validResponses
    }
    
    private static func getResponseCode(_ response: String, command: SMTPCommand) throws -> SMTPResponseCode {
        guard response.characters.count >= 3 else {
            throw SMTPError(.badResponse(command.text, response))
        }
        let range = response.startIndex..<response.index(response.startIndex, offsetBy: 3)
        guard let responseCode = Int(response[range]), command.expectedCodes.contains(SMTPResponseCode(responseCode)) else {
            throw SMTPError(.badResponse(command.text, response))
        }
        return SMTPResponseCode(responseCode)
    }
    
    private static func getResponseMessage(_ response: String) -> String {
        if response.characters.count < 4 {
            return ""
        }
        let range = response.index(response.startIndex, offsetBy: 4)..<response.endIndex
        return response[range]
    }
    
    func close() {
        socket.close()
    }
}
