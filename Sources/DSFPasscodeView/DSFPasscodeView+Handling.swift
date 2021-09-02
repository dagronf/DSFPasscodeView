//
//  DSFNumericalPasscodeView.swift
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
import AppKit

/// Protocol for managing content within the Passcode control
@objc public protocol DSFNumericalPasscodeViewHandling: NSObjectProtocol {
	/// Called when the passcode contains 'valid' content
	/// - Parameters:
	///   - view: The passcode view
	///   - passcode: The string containing the valid content
	func passcodeView(_ view: DSFPasscodeView, updatedPasscodeValue passcode: String)


	/// Called when the user either types an unsupported character, or presses an invalid key (eg. home)
	/// - Parameters:
	///   - view: The passcode view
	///   - passcode: The string containing the valid content
	///   - index: The zero-based index of the cell where it was atttempted
	func passcodeView(_ view: DSFPasscodeView, didTryInvalidCharacter invalidChar: String?, atIndex index: Int)
}

extension DSFNumericalPasscodeViewHandling {
	func passcodeView(_ view: DSFPasscodeView, updatedPasscodeValue passcode: String) {
		// Default implementation - do nothing
	}

	func passcodeView(_ view: DSFPasscodeView, didTryInvalidCharacter invalidChar: String?, atIndex index: Int) {
		// Default implementation - do nothing
	}
}

/// Custom validation block type.
///
/// Takes a string element and returns either a value transformed string element (for example, uppercased),
/// or nil if the presented character isn't valid for the control
///
/// ```swift
/// // A validator block which allows numbers and case-insensitive A-F characters
/// self.passcode.characterValidatorBlock = { element in
///    let validChars = "0123456789ABCDEF"
///    let s = element.uppercased()       // Always check against uppercase
///    if validChars.contains(s) {        // If the validChars contains the uppercased char...
///        return s.first                 //  ... return the uppercased version
///    }
///    return nil                         // Unsupported char, ignore
/// }
/// ```
public typealias DSFPasscodeCharacterValidator = (String.Element) -> String.Element?
