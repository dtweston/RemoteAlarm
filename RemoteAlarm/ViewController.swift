//
//  ViewController.swift
//  RemoteAlarm
//
//  Created by Dave Weston on 4/30/16.
//  Copyright © 2016 Binocracy. All rights reserved.
//

import UIKit
import DigitsKit

extension Trigger.Status {
    var statusText: String? {
        switch self {
        case .Initiated: return "Connecting..."
        case .Error(_): return "No Bueno"
        case .Busy: return "Busy"
        case .Cancelled: return "Error"
        case .Completed: return "Bueno"
        case .Failed: return "Error"
        case .InProgress: return "Connected"
        case .Queued: return "Connecting..."
        case .Ringing: return "Connecting..."
        case .NoAnswer: return "No Answer"
        case .Unknown: return nil
        }
    }
}

class ViewController: UIViewController, TriggerDelegate {

    @IBOutlet var statusLabel: UILabel!

    var handler: TriggerHandler?
    let trigger = Trigger()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        statusLabel.hidden = true
        trigger.delegate = self

        let authButton = DGTAuthenticateButton { (session, error) in
            if (session != nil) {

            }
        }

        authButton.center = self.view.center
        self.view.addSubview(authButton)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    @IBAction func didTap() {
        trigger.trigger(to: "+12345678901")
    }

    //- MARK TriggerDelegate methods

    func trigger(trigger: Trigger, didChangeStatus status: Trigger.Status) {
        print("New status: \(status)")
        if let text = status.statusText {
            statusLabel.text = text
        }
        statusLabel.hidden = false

        if status.isEndState {
            handler?.disconnect()
        }
    }
}

