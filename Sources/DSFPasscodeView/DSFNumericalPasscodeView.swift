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
	@VIViewInvalidating(.layout)
	@IBInspectable var groupSpacing: CGFloat = 12

	/// The spacing between individual passcode characters
	@VIViewInvalidating(.layout)
	@IBInspectable var spacing: CGFloat = 4

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
	@VIViewInvalidating(.layout)
	var font: NSFont = DSFNumericalPasscodeView.DefaultFont {
		didSet {
			self.cellViews.forEach { $0.font = self.font }
		}
	}

	/// The padding of the characters from the edges of the passcode cell
	@VIViewInvalidating(.intrinsicContentSize, .layout, .display)
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
		willSet {
			assert(newValue.filter({ $0 != "X" && $0 != "-" }).isEmpty, "Invalid pattern character (must be X or -)")
		}
		didSet {
			self.updateForPattern()
		}
	}

	/// Inset for the passcode cells within the control
	@VIViewInvalidating(.intrinsicContentSize, .layout)
	public var edgeInsets: NSEdgeInsets = NSEdgeInsets()

	/// Returns true if the passcode contains a valid passcode
	@objc public dynamic var isValidPasscode: Bool {
		return self.passcodeValue != nil
	}

	/// Returns the passcode value, or nil the passcode isn't yet valid
	@objc public private(set) dynamic var passcodeValue: String? {
		willSet {
			self.willChangeValue(for: \.isValidPasscode)
		}
		didSet {
			self.didChangeValue(for: \.isValidPasscode)
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

	private static let DefaultFontSize: CGFloat = 48
	private static let DefaultFont: NSFont = {
		return NSFont.userFixedPitchFont(ofSize: DSFNumericalPasscodeView.DefaultFontSize) ??
				NSFont(name: "Menlo", size: DSFNumericalPasscodeView.DefaultFontSize)!
	}()

	/// The number of characters in the current passcode
	private var passcodeCellCount: Int {
		self.cellViews.count
	}

	// The active cell views
	private var cellViews: [Cell] = []

	// The string containing the current cell values
	private var currentValue: String = ""

	// The index of the cell that is currently editing
	private var currentlyEditingCellIndex: Int = 0
}

extension DSFNumericalPasscodeView {
	public override func prepareForInterfaceBuilder() {
		self.cellViews.forEach { $0.content = "0" }
	}

	public override var intrinsicContentSize: NSSize {
		guard let templateCell = self.cellViews.first else { return .zero }
		let cs = templateCell.characterSize
		let h = cs.height + self.edgeInsets.top + self.edgeInsets.bottom
		var w: CGFloat = self.edgeInsets.left + self.edgeInsets.right
		self.pattern.enumerated().forEach { char in
			if char.1 == "X" {
				if char.0 != 0 {
					w += self.spacing
				}
				w += cs.width
			}
			else if char.1 == "-" {
				w += self.groupSpacing
			}
		}
		return CGSize(width: w, height: h)
	}


	public override func layout() {
		super.layout()

		guard let templateCell = self.cellViews.first else { return }
		let cs = templateCell.characterSize

		var cellOffset: Int = 0
		var xOffset: CGFloat = self.edgeInsets.left

		self.pattern.enumerated().forEach { char in
			if char.1 == "X" {
				let cell = self.cellViews[cellOffset]
				if char.0 != 0 {
					xOffset += self.spacing
				}
				cell.frame = NSRect(x: xOffset, y: self.edgeInsets.top, width: cs.width, height: cs.height)
				xOffset += cs.width

				cellOffset += 1
			}
			if char.1 == "-" {
				xOffset += self.groupSpacing
			}
		}
	}
}

public extension DSFNumericalPasscodeView {
	/// Reset the contents of the passcode view to empty
	func clear() {
		self.passcodeValue = nil
		self.cellViews.forEach {
			$0.content = ""
			$0.isEditable = false
		}
		self.currentlyEditingCellIndex = 0
		self.cellViews.first?.isEditable = true
		self.window?.makeFirstResponder(self.cellViews.first)
	}
}

extension DSFNumericalPasscodeView {
	func setup() {
		self.translatesAutoresizingMaskIntoConstraints = true
		self.pattern = "XXX-XXX"
	}
}

// MARK: - First Responder handling

public extension DSFNumericalPasscodeView {
	internal func userClickedInactiveCell() {
		// User attempted to click a cell -- make sure we focus the currently editable field
		self.window?.makeFirstResponder(self.cellViews[self.currentlyEditingCellIndex])
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

	enum UpdateType {
		case moveBack
		case moveForward
		case dontMove
		case clear
	}

	func syncCurrentValue() {
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

		let newCount = self.pattern.filter({ $0 == "X" }).count
		(0 ..< newCount).forEach { index in
			let r = Cell()
			r.font = self.font
			r.parent = self
			r.index = index
			r.allowableCharacters = self.allowableCharacters
			r.setAccessibilityTitle(Localizations.PasscodeCharAccessibilityTitle(index: index + 1, total: self.passcodeCellCount))
			self.cellViews.append(r)
			self.addSubview(r)
		}

		self.currentlyEditingCellIndex = 0
		self.cellViews.first?.isEditable = true
	}

	func cellDidUpdate(_ index: Int, _ updateType: UpdateType) {

		switch updateType {
		case .clear:
			// Pressed clear key on a numpad
			self.handleClear(index)
		case .moveBack:
			// User deleted a character using the 'backwards delete' key
			self.handleMoveBack(index)
		case .moveForward:
			// User typed a valid character
			self.handleMoveForward(index)
		case .dontMove:
			// User pressed the forward-delete key
			self.handleDontMove(index)
		}

		self.syncCurrentValue()

		/// If we have a value which matches the pattern then tell the delegate
		if self.passcodeCellCount == self.currentValue.count {
			self.passcodeValue = self.currentValue
			self.delegate?.passcodeView(self, updatedPasscodeValue: self.currentValue)
		}
		else {
			if self.passcodeValue != nil {
				self.passcodeValue = nil
			}
		}
	}
}

// MARK: - Handle cell events

extension DSFNumericalPasscodeView {
	func handleClear(_ index: Int) {
		self.clear()
		return
	}

	func handleMoveBack(_ index: Int) {
		// User deleted a character using the 'backwards delete' key
		self.currentlyEditingCellIndex = max(0, index - 1)

		self.cellViews.enumerated().forEach { cell in
			cell.1.isEditable = cell.0 == self.currentlyEditingCellIndex
			if cell.0 > self.currentlyEditingCellIndex {
				cell.1.content = ""
			}
			if cell.0 == self.currentlyEditingCellIndex {
				cell.1.window?.makeFirstResponder(cell.1)
			}
		}
	}

	func handleMoveForward(_ index: Int) {
		// User typed a valid character
		self.currentlyEditingCellIndex = min(self.passcodeCellCount - 1, index + 1)

		self.cellViews.enumerated().forEach { cell in
			cell.1.isEditable = cell.0 == self.currentlyEditingCellIndex
			if cell.0 > self.currentlyEditingCellIndex {
				cell.1.content = ""
			}
		}

		if index != self.passcodeCellCount - 1 {
			let cell = self.cellViews[index + 1]
			self.window?.makeFirstResponder(cell)
		}
		else {
			self.window?.makeFirstResponder(nil)
		}
	}

	func handleDontMove(_ index: Int) {
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
}
