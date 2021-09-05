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

extension DSFPasscodeView {
	class Cell: NSView {
		@VIViewInvalidating(.layout, .intrinsicContentSize, .display)
		var font = NSFont.userFixedPitchFont(ofSize: 48)! {
			didSet {
				self.characterDimensions = self.calculateZeroCharacterSize()
				self.textLayer.font = self.font
				self.textLayer.fontSize = self.font.pointSize
			}
		}
		
		var fontSize: CGFloat { self.font.pointSize }
		var insetSize: CGFloat { self.fontSize / 6.0 }
		
		@VIViewInvalidating(.intrinsicContentSize, .display)
		var padding = CGSize(width: 8, height: 8) {
			didSet {
				self.characterDimensions = self.calculateZeroCharacterSize()
			}
		}
		
		@VIViewInvalidating(.intrinsicContentSize, .display)
		var content: String = "" {
			didSet {
				self.textLayer.string = self.content
			}
		}
		
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
		unowned var parent: DSFPasscodeView!
		
		// Paragraph style for centering a string
		private static let CenteredParagraphStyle: NSMutableParagraphStyle = {
			let p = NSMutableParagraphStyle()
			p.alignment = .center
			return p
		}()
		
		// Cached character size
		var characterDimensions: CGSize = .zero
		
		// Passcode cell index
		var index: Int = -1
		
		// Is the cell editable?
		var isEditable = false
		
		let textLayer = VerticallyAlignedTextLayer()
		let cursorLayer = CALayer()
		
		let innerShadowLayer = CAShapeLayer()
		let innerShadowMaskLayer = CAShapeLayer()
		
		// TextClientContext
		
		lazy var context: NSTextInputContext = {
			NSTextInputContext(client: self)
		}()
	}
}

// MARK: - Layer handling

extension DSFPasscodeView.Cell {
	var HideShadows: Bool {
		return ReduceTransparency || IncreaseContrast
	}
	
	override public var wantsUpdateLayer: Bool {
		return true
	}
	
	func setupLayers() {
		self.wantsLayer = true
		
		guard let base = self.layer else { fatalError() }
		base.cornerRadius = 4
		base.borderWidth = 1
		
		// Shadow layer
		
		base.addSublayer(self.innerShadowLayer)
		self.innerShadowLayer.zPosition = -5
		self.innerShadowLayer.shadowColor = NSColor.black.cgColor
		self.innerShadowLayer.shadowOpacity = 0.8
		self.innerShadowLayer.shadowRadius = 0.5
		self.innerShadowLayer.shadowOffset = CGSize(width: 0, height: 0)
		self.innerShadowLayer.mask = self.innerShadowMaskLayer
		
		// Cursor layer
		
		base.addSublayer(self.cursorLayer)
		self.cursorLayer.zPosition = -10
		self.cursorLayer.cornerRadius = 2
		
		// Text Layer
		
		base.addSublayer(self.textLayer)
		self.cursorLayer.zPosition = -20
		self.textLayer.contentsScale = 2
		self.textLayer.alignmentMode = .center
		
		self.textLayer.shadowColor = NSColor.black.cgColor
		self.textLayer.shadowOpacity = 0.8
		self.textLayer.shadowRadius = 0.5
		self.textLayer.shadowOffset = .zero // CGSize(width: 1, height: -1)
	}
	
	override func updateLayer() {
		super.updateLayer()
		
		guard let base = self.layer else { return }
		
		self.textLayer.foregroundColor = self.textColor
		base.backgroundColor = self.backgroundColor
		base.borderColor = self.borderColor
		self.cursorLayer.backgroundColor = self.cursorColor
		
		self.innerShadowLayer.shadowColor = self.HideShadows ? .clear : NSColor.black.withAlphaComponent(0.8).cgColor
		self.textLayer.shadowColor = self.HideShadows ? .clear : NSColor.black.withAlphaComponent(0.5).cgColor
	}
	
	override func layout() {
		super.layout()
		
		self.textLayer.frame = self.bounds
		self.cursorLayer.frame = self.bounds.insetBy(dx: insetSize, dy: insetSize)
		
		// Update the inner shadow
		self.innerShadowLayer.frame = self.bounds
		
		let path = NSBezierPath(roundedRect: bounds.insetBy(dx: 0, dy: 0), xRadius: 3, yRadius: 3)
		let cutout = NSBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 1), xRadius: 3, yRadius: 3).reversed
		path.append(cutout)
		self.innerShadowLayer.path = path.cgPath
		self.innerShadowMaskLayer.path = NSBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 1), xRadius: 3, yRadius: 3).cgPath
	}
}

// MARK: - Drawing and Sizing

extension DSFPasscodeView.Cell {
	func setup() {
		self.translatesAutoresizingMaskIntoConstraints = true
		self.characterDimensions = self.calculateZeroCharacterSize()
		self.setupLayers()
	}
	
	override var intrinsicContentSize: NSSize {
		return self.characterDimensions
	}
	
	private func calculateZeroCharacterSize() -> CGSize {
		let atts: [NSAttributedString.Key: Any] = [
			.font: self.font as Any,
			.foregroundColor: NSColor.textColor,
		]
		let charS: NSString = "0"
		let charSize = charS.size(withAttributes: atts)
		return CGSize(width: charSize.width + padding.width * 2,
						  height: charSize.height + padding.height * 2)
	}
}

// MARK: - Keyboard handling

extension DSFPasscodeView.Cell {
	override func keyDown(with event: NSEvent) {
		guard let firstChar = event.characters?.first else {
			super.keyDown(with: event)
			return
		}
		self.handleNewCharacter(firstChar, with: event)
	}
	
	func handleNewCharacter(_ firstChar: String.Element, with event: NSEvent?) {
		if let validator = self.parent.characterValidatorBlock {
			// If we have a custom validator block then use it
			if let replacement = validator(firstChar) {
				self.content = String(replacement)
				self.parent.cellDidUpdate(self.index, .moveForward)
				return
			}
		}
		else {
			// Use the allowable characters as a fallback
			if self.parent.allowableCharacters.contains(firstChar) {
				self.content = String(firstChar)
				self.parent.cellDidUpdate(self.index, .moveForward)
				return
			}
		}
		
		guard let event = event else {
			self.parent.notifyUserOfInvalidCharacter(ch: String(firstChar), index: self.index)
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
		case kVK_ANSI_KeypadClear:
			self.parent.cellDidUpdate(self.index, .clear)
		case kVK_Tab:
			super.keyDown(with: event)
			return
		case kVK_Escape:
			super.keyDown(with: event)
			return
		default:
			self.parent.notifyUserOfInvalidCharacter(ch: String(firstChar), index: self.index)
			return
		}
	}
}

// MARK: - Focus and Responder

extension DSFPasscodeView.Cell {
	override var acceptsFirstResponder: Bool {
		let r = self.isEnabled && self.isEditable
		if r == false {
			self.parent.userClickedInactiveCell()
		}
		return r
	}
	
	override var focusRingMaskBounds: NSRect {
		return self.bounds
	}
	
	override func becomeFirstResponder() -> Bool {
		self.needsDisplay = true
		return super.becomeFirstResponder()
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

extension DSFPasscodeView.Cell {
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

// MARK: NSTextInputClient support

// Implement the NSTextInputClient in order to handle 'automatic' things, like double-click from Character View
// See 'Creating a Custom Text View' in the Apple documentation
// https://developer.apple.com/library/archive/documentation/TextFonts/Conceptual/CocoaTextArchitecture/TextEditing/TextEditing.html#//apple_ref/doc/uid/TP40009459-CH3

extension DSFPasscodeView.Cell: NSTextInputClient {
	// Pretend to be a text field
	override var inputContext: NSTextInputContext? {
		return self.context
	}
	
	func insertText(_ string: Any, replacementRange: NSRange) {
		if let s = string as? String, let ch = s.first {
			self.handleNewCharacter(ch, with: nil)
		}
	}
	
	func setMarkedText(_ string: Any, selectedRange: NSRange, replacementRange: NSRange) {}
	
	func unmarkText() {}
	
	func selectedRange() -> NSRange {
		return NSRange(location: 0, length: 0)
	}
	
	func markedRange() -> NSRange {
		return NSRange(location: 0, length: 0)
	}
	
	func hasMarkedText() -> Bool {
		return false
	}
	
	func attributedSubstring(forProposedRange range: NSRange, actualRange: NSRangePointer?) -> NSAttributedString? {
		return nil
	}
	
	func validAttributesForMarkedText() -> [NSAttributedString.Key] {
		return []
	}
	
	func firstRect(forCharacterRange range: NSRange, actualRange: NSRangePointer?) -> NSRect {
		return .zero
	}
	
	func characterIndex(for point: NSPoint) -> Int {
		return 0
	}
}

// MARK: - Colors

extension DSFPasscodeView.Cell {
	var backgroundColor: CGColor {
		if isEnabled {
			if isDarkMode() {
				return NSColor.controlBackgroundColor.withAlphaComponent(0.5).cgColor
			}
			else {
				return NSColor.controlBackgroundColor.cgColor
			}
		}
		else {
			if isDarkMode() {
				return NSColor.textColor.withAlphaComponent(0.05).cgColor
			}
			else {
				return NSColor.controlBackgroundColor.cgColor
			}
		}
	}
	
	var borderColor: CGColor {
		if IncreaseContrast {
			if isEnabled {
				return NSColor.textColor.cgColor
			}
			else {
				return isDarkMode() ? NSColor.disabledControlTextColor.cgColor : NSColor.quaternaryLabelColor.cgColor
			}
		}
		else {
			if isEnabled {
				return NSColor.secondaryLabelColor.cgColor
			}
			else {
				return NSColor.placeholderTextColor.cgColor
			}
		}
	}
	
	var textColor: CGColor {
		if isEnabled {
			return NSColor.textColor.cgColor
		}
		else {
			return isDarkMode() ? NSColor.disabledControlTextColor.cgColor : NSColor.quaternaryLabelColor.cgColor
		}
	}
	
	var cursorColor: CGColor? {
		if isEnabled {
			if self.window?.firstResponder == self, self.window?.isKeyWindow ?? false {
				return NSColor.selectedTextBackgroundColor.withAlphaComponent(IncreaseContrast ? 0.2 : 0.4).cgColor
			}
			else {
				return nil
			}
		}
		else {
			return nil
		}
	}
}
