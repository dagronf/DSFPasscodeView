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
import VIViewInvalidating

/// A passcode control like Apple's two-factor authentication screen
@IBDesignable
public class DSFNumericalPasscodeView: NSView {

	/// The delegate to receive updates
	@IBOutlet weak var delegate: DSFNumericalPasscodeViewHandling?

	/// Configure the font name of the font to be used. If the font cannot be found no changes are made.
	@IBInspectable var fontName: String = "Menlo" {
		didSet {
			if let font = NSFont(name: self.fontName, size: self.fontSize) {
				self.font = font
			}
		}
	}

	/// Configure the font size of the font to be used. If the font cannot be found no changes are made.
	@IBInspectable var fontSize: CGFloat = 42 {
		didSet {
			if let font = NSFont(name: self.font.fontName, size: self.fontSize) {
				self.font = font
			}
		}
	}

	/// The spacing between passcode groupings
	@IBInspectable var groupSpacing: CGFloat = 12 {
		didSet {
			self.stack.spacing = groupSpacing
		}
	}

	/// The spacing between individual passcode characters
	@IBInspectable var spacing: CGFloat = 4 {
		didSet {
			self.stack.arrangedSubviews
				.compactMap { $0 as? NSStackView }
				.forEach { $0.spacing = spacing }
		}
	}

	/// The spacing of the characters from the leading and trailing edges of the passcode character cell
	@IBInspectable var xPadding: CGFloat = 8 {
		didSet {
			var p = self.padding
			p.width = self.xPadding
			self.padding = p
		}
	}

	/// The spacing of the characters from the top and bottom edges of the passcode character cell
	@IBInspectable var yPadding: CGFloat = 4 {
		didSet {
			var p = self.padding
			p.height = self.yPadding
			self.padding = p
		}
	}

	/// Configure the font size of the font to be used. If the font cannot be found no changes are made.
	var font: NSFont = DSFNumericalPasscodeView.DefaultFont {
		didSet {
			self.cellViews.forEach { $0.font = self.font }
		}
	}

	/// The padding of the characters from the edges of the passcode cell
	@VIViewInvalidating(.intrinsicContentSize, .display)
	var padding: CGSize = CGSize(width: 8, height: 4) {
		didSet {
			self.cellViews.forEach { $0.padding = self.padding }
		}
	}

	/// The enabled state for the control
	@IBInspectable
	@objc public dynamic var isEnabled: Bool = true {
		didSet {
			self.cellViews.forEach { $0.isEnabled = self.isEnabled }
		}
	}

	/// The set of allowable characters within the control
	@IBInspectable
	public var allowableCharacters: String = "0123456789" {
		didSet {
			self.updateForPattern()
		}
	}

	/// The pattern to use when displaying the passcode
	@IBInspectable
	public var pattern: String = "XXX-XXX" {
		didSet {
			self.updateForPattern()
		}
	}

	/// The number of characters in the current passcode
	public var passcodeCharCount: Int {
		self.cellViews.count
	}

	/// Returns true if the passcode contains a valid passcode
	@objc public var isValid: Bool = false

	override init(frame frameRect: NSRect) {
		super.init(frame: frameRect)
		self.setup()
	}

	required init?(coder: NSCoder) {
		super.init(coder: coder)
		self.setup()
	}

	// Private

	private static let DefaultFontSize: CGFloat = 48
	private static let DefaultFont: NSFont = {
		return NSFont.userFixedPitchFont(ofSize: DSFNumericalPasscodeView.DefaultFontSize) ??
				NSFont(name: "Menlo", size: DSFNumericalPasscodeView.DefaultFontSize)!
	}()

	private var cellViews: [Cell] = []

	var currentValue: String = ""

	let stack: NSStackView = {
		let s = NSStackView()
		s.translatesAutoresizingMaskIntoConstraints = false
		s.orientation = .horizontal
		s.spacing = 4
		s.setHuggingPriority(.defaultHigh, for: .horizontal)
		s.setHuggingPriority(.defaultHigh, for: .vertical)
		return s
	}()


	enum UpdateType {
		case moveBack
		case moveForward
		case dontMove
	}

	public override func prepareForInterfaceBuilder() {
		self.cellViews.forEach { $0.content = "0" }
	}
}

public extension DSFNumericalPasscodeView {
	/// Reset the contents of the passcode view to empty
	func clear() {
		self.cellViews.forEach {
			$0.content = ""
			$0.isEditable = false
		}
		self.cellViews.first?.isEditable = true
		self.window?.makeFirstResponder(self.cellViews.first)
	}
}

extension DSFNumericalPasscodeView {
	func setup() {
		self.translatesAutoresizingMaskIntoConstraints = false
		self.addSubview(self.stack)
		self.stack.pinEdges(to: self)

		self.setContentHuggingPriority(.required, for: .horizontal)

		self.pattern = "XXX-XXX"
	}
}

// MARK: - First Responder handling

public extension DSFNumericalPasscodeView {
	override var acceptsFirstResponder: Bool {
		return true
	}

	override func becomeFirstResponder() -> Bool {
		for c in self.cellViews {
			if c.content == "" {
				self.window?.makeFirstResponder(c)
				return true
			}
		}
		self.window?.makeFirstResponder(self.cellViews.last)
		return true
	}
}

// MARK: - Accessibility

public extension DSFNumericalPasscodeView {
	override func isAccessibilityElement() -> Bool {
		 return true
	}

	override func accessibilityRole() -> NSAccessibility.Role? {
		return NSAccessibility.Role(rawValue: "Numerical Passcode")
	}

	override func accessibilityRoleDescription() -> String? {
		return Localizations.PasscodeRoleDescription(totalCharacters: self.cellViews.count)
	}

	/// Use the accessibility identifier value to uniquely identify THIS passcode
	override func accessibilityLabel() -> String? {
		return Localizations.PasscodeControl(identificationString: self.accessibilityIdentifier())
	}
}

// MARK: - Update and sync

extension DSFNumericalPasscodeView {

	func syncValue() {
		self.currentValue = ""
		for cell in self.cellViews {
			if cell.content.count == 0 {
				return
			}
			self.currentValue += cell.content
		}
	}

	func updateForPattern() {
		self.cellViews.forEach { $0.removeFromSuperview() }
		self.cellViews = []
		self.stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
		self.stack.spacing = self.groupSpacing

		var currentGroup: NSStackView? = nil

		var count = 0
		pattern.forEach { ch in
			if ch == "X" {
				if currentGroup == nil {
					currentGroup = NSStackView()
					currentGroup?.translatesAutoresizingMaskIntoConstraints = false
					currentGroup?.orientation = .horizontal
					currentGroup?.distribution = .fillEqually
					currentGroup?.spacing = self.spacing
				}

				let r = Cell()
				r.font = self.font
				r.parent = self
				r.index = count
				r.allowableCharacters = self.allowableCharacters
				r.setAccessibilityTitle(Localizations.PasscodeCharAccessibilityTitle(index: count + 1, total: self.passcodeCharCount))
				self.cellViews.append(r)
				currentGroup?.addArrangedSubview(r)
				count += 1
			}
			else if ch == "-" {
				if let c = currentGroup {
					self.stack.addArrangedSubview(c)
				}
				currentGroup = nil
			}
		}

		if let c = currentGroup {
			self.stack.addArrangedSubview(c)
		}

		self.cellViews.first?.isEditable = true

		self.window?.recalculateKeyViewLoop()
	}

	func cellDidUpdate(_ index: Int, _ updateType: UpdateType) {
		if updateType == .moveBack {
			// User deleted a character
			let affectedCells = self.cellViews.suffix(self.cellViews.count - index - 1)
			affectedCells.forEach {
				$0.content = ""
				$0.isEditable = false
			}
		}

		if updateType == .moveForward {
			// User added a character
			self.cellViews[index].isEditable = true
			if index < self.cellViews.count - 1 {
				self.cellViews[index + 1].isEditable = true
				let affectedCells = self.cellViews.suffix(self.cellViews.count - index - 2)
				affectedCells.forEach {
					if $0.content.count > 0 {
						$0.isEditable = true
					}
					else {
						$0.isEditable = false
					}
				}
			}
		}

		if updateType == .dontMove {
			// User pressed the forward-delete key
			self.cellViews[index].isEditable = true
			if index < self.cellViews.count - 1 {
				self.cellViews[index + 1].isEditable = true
				let affectedCells = self.cellViews.suffix(self.cellViews.count - index - 1)
				affectedCells.forEach {
					$0.content = ""
					$0.isEditable = false
				}
			}
		}

		self.syncValue()

		switch updateType {
		case .moveForward:
			self.cellViews.forEach {
				if $0.index == index + 1 {
					$0.window?.makeFirstResponder($0)
					$0.isEditable = true
				}
				else {
					$0.isEditable = false
				}
			}

			if index == self.cellViews.count - 1 {
				self.window?.makeFirstResponder(self.nextKeyView)
			}
		case .moveBack:
			self.cellViews.forEach {
					if $0.index == index - 1 {
						$0.window?.makeFirstResponder($0)
					}
				}
		case .dontMove:
			_ = 5
			// Do nothing
		}

		/// If we have a value which matches the pattern then tell the delegate
		if pattern.filter({ $0 == "X" }).count == self.currentValue.count {
			Swift.print(self.currentValue)
			self.isValid = true
			self.delegate?.passcodeView(self, updatedPasscodeValue: self.currentValue)
		}
		else {
			self.isValid = false
		}
	}
}
