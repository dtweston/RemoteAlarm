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
        case .initiated: return "Connecting..."
        case .error(_): return "No Bueno"
        case .busy: return "Busy"
        case .cancelled: return "Error"
        case .completed: return "Bueno"
        case .failed: return "Error"
        case .inProgress: return "Connected"
        case .queued: return "Connecting..."
        case .ringing: return "Connecting..."
        case .noAnswer: return "No Answer"
        case .unknown: return nil
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

        statusLabel.isHidden = true
        trigger.delegate = self

        let authButton = DGTAuthenticateButton { (session, error) in
            if (session != nil) {

            }
        }

        authButton?.center = self.view.center
        self.view.addSubview(authButton!)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    @IBAction func didTap() {
        trigger.trigger(to: "+12345678901")
    }

    //- MARK TriggerDelegate methods

    func trigger(_ trigger: Trigger, didChangeStatus status: Trigger.Status) {
        print("New status: \(status)")
        if let text = status.statusText {
            statusLabel.text = text
        }
        statusLabel.isHidden = false

        if status.isEndState {
            handler?.disconnect()
        }
    }
}

