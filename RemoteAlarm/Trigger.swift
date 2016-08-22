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
    private let socket: WebSocket
    private weak var trigger: Trigger?

    init(url: NSURL, trigger: Trigger) {
        socket = WebSocket(url: url)
        socket.delegate = self
        self.trigger = trigger
        socket.connect()
    }

    func dial(number: String) throws {
        let data = try NSJSONSerialization.dataWithJSONObject(["command": "dial", "params": ["toNumber": number]], options: .PrettyPrinted)
        if let jsonString = String(data: data, encoding: NSUTF8StringEncoding) {
            socket.writeString(jsonString)
        }
        trigger?.delegate?.trigger(trigger!, didChangeStatus: .Initiated)
    }

    func disconnect() {
        socket.disconnect()
    }

    func websocketDidConnect(socket: WebSocket) {
        print("Did connect")
    }

    func websocketDidReceiveData(socket: WebSocket, data: NSData) {
        print("Did receive data: \(data)")
    }

    func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        print("Did disconnect with error? \(error)")
    }

    func websocketDidReceiveMessage(socket: WebSocket, text: String) {
        print("Did receive message: \(text)")
        do {
            if let data = text.dataUsingEncoding(NSUTF8StringEncoding) {
                let update = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
                if let statusObj = update["status"] as? String {
                    let status = Trigger.statusFromString(statusObj)
                    trigger?.delegate?.trigger(trigger!, didChangeStatus: status)
                }
            }
        }
        catch let ex as NSError {
            trigger?.delegate?.trigger(trigger!, didChangeStatus: .Error(Trigger.Error.JsonParseError))
            print("Unable to parse JSON update: \(ex)")
        }
    }
}

protocol TriggerDelegate: class {
    func trigger(trigger: Trigger, didChangeStatus: Trigger.Status)
}

class Trigger {
    enum Error: ErrorType {
        case JsonFormatError
        case JsonParseError
    }

    enum Status {
        case Unknown
        case Initiated
        case Error(ErrorType)
        case Queued
        case Ringing
        case InProgress
        case Cancelled
        case Completed
        case Failed
        case Busy
        case NoAnswer

        var isEndState: Bool {
            switch self {
            case .Unknown: fallthrough
            case .Queued: fallthrough
            case .Ringing: fallthrough
            case .InProgress:
                return false
            default:
                return true
            }
        }
    }

    weak var delegate: TriggerDelegate?
    private var handlers: [TriggerHandler] = []

    func trigger(to toNumber: String) {
        let handler = TriggerHandler(url: NSURL(string: "ws://localhost:3003/")!, trigger: self)
        handler.socket.onConnect = { [unowned self ] _ in
            do {
                try handler.dial("+12345678901")
            }
            catch {
                self.delegate?.trigger(self, didChangeStatus: .Error(Error.JsonFormatError))
            }
        }

        handlers.append(handler)
    }

    static func statusFromString(statusVal: String) -> Status {
        switch statusVal {
        case "initiated": return .Initiated
        case "queued": return .Queued
        case "ringing": return .Ringing
        case "in-progress": return .InProgress
        case "canceled": return .Cancelled
        case "completed": return .Completed
        case "failed": return .Failed
        case "busy": return .Busy
        case "no-answer": return .NoAnswer
        default:
            return .Unknown
        }
    }
}
