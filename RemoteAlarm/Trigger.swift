//
//  Trigger.swift
//  RemoteAlarm
//
//  Created by Dave Weston on 5/4/16.
//  Copyright © 2016 Binocracy. All rights reserved.
//

import Foundation
import Alamofire
import Starscream

class TriggerHandler: WebSocketDelegate {
    fileprivate let socket: WebSocket
    fileprivate weak var trigger: Trigger?

    init(url: URL, trigger: Trigger) {
        socket = WebSocket(url: url)
        socket.delegate = self
        self.trigger = trigger
        socket.connect()
    }

    func dial(_ number: String) throws {
        let data = try JSONSerialization.data(withJSONObject: ["command": "dial", "params": ["toNumber": number]], options: .prettyPrinted)
        if let jsonString = String(data: data, encoding: String.Encoding.utf8) {
            socket.write(string: jsonString)
        }
        trigger?.delegate?.trigger(trigger!, didChangeStatus: .initiated)
    }

    func disconnect() {
        socket.disconnect()
    }

    func websocketDidConnect(socket: WebSocket) {
        print("Did connect")
    }

    func websocketDidReceiveData(socket: WebSocket, data: Data) {
        print("Did receive data: \(data)")
    }

    func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        print("Did disconnect with error? \(error)")
    }

    func websocketDidReceiveMessage(socket: WebSocket, text: String) {
        print("Did receive message: \(text)")
        do {
            if let data = text.data(using: .utf8) {
                let update = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
                if let up = update as? [String: Any],
                    let statusObj = up["status"] as? String {
                    let status = Trigger.statusFromString(statusObj)
                    trigger?.delegate?.trigger(trigger!, didChangeStatus: status)
                }
            }
        }
        catch let ex as NSError {
            trigger?.delegate?.trigger(trigger!, didChangeStatus: .error(Trigger.Error.jsonParseError))
            print("Unable to parse JSON update: \(ex)")
        }
    }
}

protocol TriggerDelegate: class {
    func trigger(_ trigger: Trigger, didChangeStatus: Trigger.Status)
}

class Trigger {
    enum Error: Swift.Error {
        case jsonFormatError
        case jsonParseError
    }

    enum Status {
        case unknown
        case initiated
        case error(Error)
        case queued
        case ringing
        case inProgress
        case cancelled
        case completed
        case failed
        case busy
        case noAnswer

        var isEndState: Bool {
            switch self {
            case .unknown: fallthrough
            case .queued: fallthrough
            case .ringing: fallthrough
            case .inProgress:
                return false
            default:
                return true
            }
        }
    }

    weak var delegate: TriggerDelegate?
    fileprivate var handlers: [TriggerHandler] = []

    func trigger(to toNumber: String) {
        let handler = TriggerHandler(url: URL(string: "ws://localhost:3003/")!, trigger: self)
        handler.socket.onConnect = { [unowned self ] _ in
            do {
                try handler.dial("+12345678901")
            }
            catch {
                self.delegate?.trigger(self, didChangeStatus: .error(Error.jsonFormatError))
            }
        }

        handlers.append(handler)
    }

    static func statusFromString(_ statusVal: String) -> Status {
        switch statusVal {
        case "initiated": return .initiated
        case "queued": return .queued
        case "ringing": return .ringing
        case "in-progress": return .inProgress
        case "canceled": return .cancelled
        case "completed": return .completed
        case "failed": return .failed
        case "busy": return .busy
        case "no-answer": return .noAnswer
        default:
            return .unknown
        }
    }
}
