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
	@IBOutlet var passcode: DSFPasscodeView!

	@IBOutlet weak var alphaPasscode: DSFPasscodeView!

	func applicationDidFinishLaunching(_ aNotification: Notification) {
		// custom character validator
		self.passcode.delegate = self

		// Custom validator block - hex characters
		self.alphaPasscode.characterValidatorBlock = { element in

			guard let e = element.unicodeScalars.first else { return nil }
			if CharacterSet.alphanumerics.contains(e) {
				return element.uppercased().first
			}
			if element == "😀" { return element }
			return nil
		}

		self.window.makeFirstResponder(self.passcode)
	}

	func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
	}

	@IBAction func resetPasscode(_ sender: Any) {
		self.passcode.clear()
	}

	@IBAction func toggleIsEditable(_ sender: NSButton) {
		self.passcode.isEnabled = (sender.state == .on)
	}
}

extension AppDelegate: DSFPasscodeViewHandling {
	func passcodeViewDidChange(_ view: DSFPasscodeView) {
		if view === alphaPasscode {
			Swift.print("ALPHA PASSCODE: changed...")
		}
		else {
			Swift.print("PASSCODE: changed...")
		}
	}

	func passcodeView(_ view: DSFPasscodeView, validPasscodeValue passcode: String) {
		if view === alphaPasscode {
			Swift.print("ALPHA PASSCODE: New valid passcode -> \(passcode)")
		}
		else {
			Swift.print("PASSCODE: New valid passcode -> \(passcode)")
		}
	}

	func passcodeView(_ view: DSFPasscodeView, didTryInvalidCharacter invalidChar: String?, atIndex index: Int) {
		if view === alphaPasscode {
			Swift.print("ALPHA PASSCODE: Invalid character \(invalidChar ?? "<undefined>") at index \(index)")
		}
		else {
			Swift.print("PASSCODE: Invalid character \(invalidChar ?? "<undefined>") at index \(index)")
		}
		NSSound.beep()
	}
}
