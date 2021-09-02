//
//  AppDelegate.swift
//  Simple DSFPasscodeView Demo
//
//  Created by Darren Ford on 1/9/21.
//

import Cocoa
import DSFPasscodeView

@main
class AppDelegate: NSObject, NSApplicationDelegate {

	@IBOutlet var window: NSWindow!
	@IBOutlet weak var passcode: DSFNumericalPasscodeView!

	var observer1: NSKeyValueObservation?
	var observer2: NSKeyValueObservation?

	func applicationDidFinishLaunching(_ aNotification: Notification) {
		// Insert code here to initialize your application

		self.observer1 = self.passcode.observe(\.passcodeValue, options: [.new]) { me, value in
			Swift.print("\(value.newValue)")
		}

		self.observer2 = self.passcode.observe(\.isValidPasscode, options: [.new]) { me, value in
			Swift.print("\(value.newValue)")
		}
	}

	func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
	}

	@IBAction func resetPasscode(_ sender: Any) {
		self.passcode.clear()
	}

	@IBAction func toggleIsEditable(_ sender: Any) {
		self.passcode.isEnabled.toggle()
	}
}

