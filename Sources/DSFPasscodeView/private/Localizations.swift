//
//  Localizations.swift
//
//  Created by Darren Ford on 2/9/21.
//
//  MIT License
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation

public enum Localizations {
	static func PasscodeControl(identificationString: String) -> String {
		if identificationString.isEmpty {
			return NSLocalizedString("Numerical Passcode", comment: "The accessibility string provided for a Passcode control")
		}
		else {
			let formatStr = NSLocalizedString("Numerical Passcode (%1$@)", comment: "The accessibility string provided for a Passcode control with an identifying string")
			return String(format: formatStr, identificationString)
		}
	}

	static let PasscodeChar = NSLocalizedString("Passcode Cell", comment: "An individual character cell within the control")

	static func PasscodeCharAccessibilityTitle(index: Int, total: Int) -> String {
		let formatStr = NSLocalizedString("Passcode Cell %1$d of %2$d", comment: "Identifying a passcode cell by its position from leading edge of the control. English format example: 'Passcode Character 1 of 4'")
		return String(format: formatStr, index, total)
	}

	static func PasscodeRoleDescription(totalCharacters: Int) -> String {
		let formatStr = NSLocalizedString("Numerical Passcode with %1$d cells", comment: "The passcode title string, used for Accessibility")
		return String(format: formatStr, totalCharacters)
	}
}
