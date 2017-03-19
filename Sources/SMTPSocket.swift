//
//  SMTPSocket.swift
//  KituraSMTP
//
//  Created by Quan Vo on 3/16/17.
//
//

import Foundation
import Socket

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
        print(commandText)
        _ = try socket.write(from: commandText + CRLF)
    }
    
    func readFromSocket() throws -> String {
        var buf = Data()
        _ = try socket.read(into: &buf)
        guard let res = String(data: buf, encoding: .utf8) else {
            throw SMTPError(.convertDataUTF8Fail(buf))
        }
        print(res)
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
        let range = response.startIndex..<response.index(response.startIndex, offsetBy: 3)
        guard let responseCode = Int(response[range]), command.expectedCodes.contains(SMTPResponseCode(responseCode)) else {
            throw SMTPError(.badResponse(command.text, response))
        }
        return SMTPResponseCode(responseCode)
    }
    
    private static func getResponseMessage(_ response: String) -> String {
        let range = response.index(response.startIndex, offsetBy: 4)..<response.endIndex
        return response[range]
    }
}
