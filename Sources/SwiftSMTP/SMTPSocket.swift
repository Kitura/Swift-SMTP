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

// Wrapper around BlueSocket
struct SMTPSocket {
    // The socket we use to read and write to
    private let socket: Socket

    // Init a new instance of SMTPSocket
    init() throws {
        socket = try Socket.create()
    }

    // Connect to the SMTP server at `port`
    func connect(to: String, port: Int32, timeout: UInt) throws {
        try socket.connect(to: to, port: port, timeout: timeout)
    }

    // Set the socket's `SSLServiceDelegate` for SSL connections
    func setDelegate(_ delegate: SSLServiceDelegate?) {
        socket.delegate = delegate
    }

    // Close the socket
    func close() {
        socket.close()
    }
}

extension SMTPSocket {
    // Send the `command` to the server
    // Read the response from the server out of the socket
    // Parse the server's response for the appropriate responses
    // Create `Response`s out of those parsed responses and return them
    // Throws an error if no/invalid response found
    // Valid responses are `command` specific
    @discardableResult
    func send(_ command: Command) throws -> [Response] {
        try write(command.text)
        return try SMTPSocket.parseResponses(try readFromSocket(), command: command)
    }
}

extension SMTPSocket {
    // Write `text` to the socket
    func write(_ text: String) throws {
        _ = try socket.write(from: text + CRLF)
        Log.debug(text)
    }

    // Write `data` to the socket
    func write(_ data: Data) throws {
        _ = try socket.write(from: data)
        Log.debug("(sending data)")
    }
}

extension SMTPSocket {
    // Read all the data out of the socket
    // Returns a string representation of the data
    // The string could be one or more responses
    // Throws an error if a string could not be created from the data
    func readFromSocket() throws -> String {
        var buf = Data()
        _ = try socket.read(into: &buf)
        guard let responses = String(data: buf, encoding: .utf8) else {
            throw SMTPError.convertDataUTF8Fail(data: buf)
        }
        Log.debug(responses)
        return responses
    }

    // Parses through each response and creates a `Response` from it
    // Returns an array of these `Response`s
    // Throws an error if no/invalid response found
    @discardableResult
    static func parseResponses(_ responses: String, command: Command) throws -> [Response] {
        let resArr = responses.components(separatedBy: CRLF)
        guard !resArr.isEmpty else {
            throw SMTPError.badResponse(command: command.text, response: responses)
        }
        var validResponses = [Response]()
        for res in resArr {
            if res == "" { break }
            validResponses.append(Response(code: try getResponseCode(res, command: command),
                                           message: getResponseMessage(res),
                                           response: res))
        }
        return validResponses
    }

    // Returns a `ResponseCode` extracted from the `response`
    // Throws an error if no/invalid response code found
    static func getResponseCode(_ response: String, command: Command) throws -> ResponseCode {
        guard response.count > 3 else {
            throw SMTPError.badResponse(command: command.text, response: response)
        }

        #if swift(>=3.2)
            guard let code = Int(response[..<response.index(response.startIndex, offsetBy: 3)]) else {
                throw SMTPError.badResponse(command: command.text, response: response)
            }
        #else
            guard let code = Int(response.substring(to: response.index(response.startIndex, offsetBy: 3))) else {
                throw SMTPError.badResponse(command: command.text, response: response)
            }
        #endif

        guard
            response.count > 2,
            command.expectedResponseCodes.map({ $0.rawValue }).contains(code) else {
                throw SMTPError.badResponse(command: command.text, response: response)
        }
        return ResponseCode(code)
    }

    // Returns the reponse message from the response
    static func getResponseMessage(_ response: String) -> String {
        guard response.count > 3 else {
            return ""
        }

        #if swift(>=3.2)
            return String(response[response.index(response.startIndex, offsetBy: 4)...])
        #else
            return response.substring(from: response.index(response.startIndex, offsetBy: 4))
        #endif
    }
}
