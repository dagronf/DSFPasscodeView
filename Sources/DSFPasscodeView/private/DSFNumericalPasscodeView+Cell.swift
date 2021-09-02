//
//  DSFNumericalPasscodeView+Cell.swift
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

import AppKit
import Carbon.HIToolbox
import Foundation
import VIViewInvalidating

extension DSFNumericalPasscodeView {
	class Cell: NSView {
		@VIViewInvalidating(.intrinsicContentSize, .display)
		var font = NSFont.userFixedPitchFont(ofSize: 48)! {
			didSet {
				self.characterSize = self.calculateCharacterSize()
			}
		}
		
		var fontSize: CGFloat { self.font.pointSize }
		var insetSize: CGFloat { self.fontSize / 6.0 }
		
		@VIViewInvalidating(.intrinsicContentSize, .display)
		var padding = CGSize(width: 8, height: 8) {
			didSet {
				self.characterSize = self.calculateCharacterSize()
			}
		}
		
		@VIViewInvalidating(.intrinsicContentSize, .display)
		var content: String = ""
		
		@VIViewInvalidating(.display)
		var isEnabled: Bool = true {
			didSet {
				if isEnabled == false {
					if self.window?.firstResponder == self {
						self.window?.makeFirstResponder(nil)
					}
				}
			}
		}
		
		override init(frame frameRect: NSRect) {
			super.init(frame: frameRect)
			self.setup()
		}
		
		required init?(coder: NSCoder) {
			super.init(coder: coder)
			self.setup()
		}
		
		// Private
		
		// Parent control
		unowned var parent: DSFNumericalPasscodeView!
		
		// Paragraph style for centering a string
		private static let CenteredParagraphStyle: NSMutableParagraphStyle = {
			let p = NSMutableParagraphStyle()
			p.alignment = .center
			return p
		}()
		
		// Cached character size
		var characterSize: CGSize = .zero
		
		/// The allowable set of characters
		var allowableCharacters: String = ""
		
		// Passcode cell index
		var index: Int = -1
		
		// Is the cell editable?
		var isEditable = false
	}
}

extension DSFNumericalPasscodeView.Cell {
	func setup() {
		self.translatesAutoresizingMaskIntoConstraints = false
		self.characterSize = self.calculateCharacterSize()
	}
}

// MARK: - Drawing

extension DSFNumericalPasscodeView.Cell {
	override var intrinsicContentSize: NSSize {
		return self.characterSize
	}
	
	func calculateCharacterSize() -> CGSize {
		let charSize = self.characterSize(self.content)
		return CGSize(width: charSize.width + padding.width * 2,
						  height: charSize.height + padding.height * 2)
	}
	
	func characterSize(_: String) -> CGSize {
		let atts: [NSAttributedString.Key: Any] = [
			.font: self.font as Any,
			.foregroundColor: NSColor.textColor,
		]
		let charS: NSString = "0"
		return charS.size(withAttributes: atts)
	}
	
	override func draw(_: NSRect) {
		let rect = self.bounds
		
		let pth = NSBezierPath(roundedRect: rect.insetBy(dx: 1, dy: 1), xRadius: 4, yRadius: 4)
		pth.lineWidth = 1
		if self.isEnabled {
			NSColor.secondaryLabelColor.setStroke()
			
			if self.content.count > 0 {
				NSColor.textBackgroundColor.setFill()
			}
			else {
				NSColor.textBackgroundColor.withAlphaComponent(0.4).setFill()
			}
			pth.fill()
		}
		else {
			NSColor.secondaryLabelColor.setStroke()
		}
		pth.stroke()
		
		if self.window?.firstResponder == self {
			let pth = NSBezierPath(roundedRect: rect.insetBy(dx: self.insetSize, dy: self.insetSize), xRadius: 2, yRadius: 2)
			let c = NSColor.selectedTextBackgroundColor.withAlphaComponent(0.4)
			c.setFill()
			pth.fill()
		}
		
		if self.content.count == 1 {
			let atts: [NSAttributedString.Key: Any] = [
				.font: self.font as Any,
				.foregroundColor: self.isEnabled ? NSColor.textColor : NSColor.placeholderTextColor,
				.paragraphStyle: Self.CenteredParagraphStyle,
			]
			let v = NSString(string: content)
			v.draw(at: CGPoint(x: self.padding.width, y: self.padding.height), withAttributes: atts)
		}
	}
}

// MARK: - Keyboard handling

extension DSFNumericalPasscodeView.Cell {
	override func keyDown(with event: NSEvent) {
		guard let firstChar = event.characters?.first else {
			super.keyDown(with: event)
			return
		}
		
		if allowableCharacters.contains(firstChar) {
			self.content = String(firstChar)
			self.parent.cellDidUpdate(self.index, .moveForward)
			return
		}
		
		// Handle some special chars
		switch Int(event.keyCode) {
		case kVK_Delete:
			self.content = ""
			self.parent.cellDidUpdate(self.index, .moveBack)
		case kVK_ForwardDelete:
			self.content = ""
			self.parent.cellDidUpdate(self.index, .dontMove)
			
		case kVK_Tab:
			super.keyDown(with: event)
			return
			
		default:
			NSSound.beep()
			return
		}
	}
}

// MARK: - Focus and Responder

extension DSFNumericalPasscodeView.Cell {
	override var acceptsFirstResponder: Bool {
		return self.isEnabled && self.isEditable
	}
	
	override var focusRingMaskBounds: NSRect {
		self.bounds
	}
	
	override func becomeFirstResponder() -> Bool {
		let r = super.becomeFirstResponder()
		self.needsDisplay = true
		return r
	}
	
	override func resignFirstResponder() -> Bool {
		let r = super.resignFirstResponder()
		self.needsDisplay = true
		return r
	}
	
	override public func drawFocusRingMask() {
		let pth = NSBezierPath(roundedRect: self.bounds, xRadius: 4, yRadius: 4)
		pth.fill()
	}
}

// MARK: - Accessibility

extension DSFNumericalPasscodeView.Cell {
	override func isAccessibilityElement() -> Bool {
		return true
	}
	
	override func accessibilityRole() -> NSAccessibility.Role? {
		NSAccessibility.Role(rawValue: "Passcode Character")
	}
	
	override func accessibilityRoleDescription() -> String? {
		return Localizations.PasscodeChar
	}
}
