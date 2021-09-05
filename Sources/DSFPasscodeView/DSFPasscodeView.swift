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

import AppKit
import Foundation
import VIViewInvalidating

/// A passcode control like Apple's two-factor authentication screen
@IBDesignable
public class DSFPasscodeView: NSView {
	/// The delegate to receive updates
	@IBOutlet weak public var delegate: DSFPasscodeViewHandling?

	/// The enabled state for the control
	@IBInspectable
	public dynamic var isEnabled: Bool = true {
		didSet {
			self.cellViews.forEach { $0.isEnabled = self.isEnabled }
		}
	}

	// MARK: - Pattern

	/// The pattern to use when displaying the passcode
	///
	/// The only valid characters are # (a character) and - (a group spacing)
	///
	/// Examples: "###-###", "####-####-##"
	@IBInspectable
	public var pattern: String = "###-###" {
		willSet {
			if newValue.count == 0 {
				fatalError("Invalid pattern character (no pattern specified)")
			}
			if newValue.filter({ $0 != "#" && $0 != "-" }).isEmpty == false {
				fatalError("Invalid pattern character (must be # or -)")
			}
		}
		didSet {
			self.updateForPattern()
		}
	}

	// MARK: - Font

	/// Configure the font size of the font to be used. If the font cannot be found no changes are made.
	@VIViewInvalidating(.layout)
	var font: NSFont = DSFPasscodeView.DefaultFont {
		didSet {
			self.cellViews.forEach { $0.font = self.font }
		}
	}

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

	// MARK: - Cell spacing

	/// The spacing between passcode groupings
	@VIViewInvalidating(.layout)
	@IBInspectable var groupSpacing: CGFloat = 12

	/// The spacing between individual passcode characters
	@VIViewInvalidating(.layout)
	@IBInspectable var cellSpacing: CGFloat = 4

	// MARK: - Text padding within each cell

	/// The padding of the characters from the edges of the passcode cell
	@VIViewInvalidating(.intrinsicContentSize, .layout, .display)
	var padding = CGSize(width: 8, height: 4) {
		didSet {
			self.cellViews.forEach { $0.padding = self.padding }
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

	/// Inset for the passcode cells within the control
	@VIViewInvalidating(.intrinsicContentSize, .layout)
	public var edgeInsets = NSEdgeInsets()

	// MARK: - Character validations

	/// A custom character validation block
	///
	/// Can be used to transform 'valid' characters before returning them (for example, uppercasing)
	public var characterValidatorBlock: DSFPasscodeCharacterValidator?

	/// The set of allowable characters within the control, used when the validator block is missing
	@IBInspectable
	public var allowableCharacters: String = "0123456789" {
		didSet {
			self.updateForPattern()
		}
	}

	/// Returns true if the passcode contains a valid passcode
	@objc public dynamic var isValidPasscode: Bool {
		return self.passcodeValue != nil
	}

	/// Returns true if the passcode is empty (no characters entered)
	@objc public private(set) dynamic var isEmpty: Bool = true

	/// Returns the passcode value, or nil the passcode isn't yet valid
	@objc public private(set) dynamic var passcodeValue: String? {
		willSet {
			self.willChangeValue(for: \.isValidPasscode)
		}
		didSet {
			self.didChangeValue(for: \.isValidPasscode)
		}
	}

	// MARK: - init/deinit

	override init(frame frameRect: NSRect) {
		super.init(frame: frameRect)
		self.setup()
	}

	required init?(coder: NSCoder) {
		super.init(coder: coder)
		self.setup()
	}

	deinit {
		self.delegate = nil
		self.characterValidatorBlock = nil
		self.removeAllCells()
	}

	// Private

	private static let DefaultFontSize: CGFloat = 48
	private static let DefaultFont: NSFont = {
		NSFont.userFixedPitchFont(ofSize: DSFPasscodeView.DefaultFontSize) ??
		NSFont(name: "Menlo", size: DSFPasscodeView.DefaultFontSize)!
	}()

	/// The number of characters in the current passcode
	private var passcodeCellCount: Int {
		self.pattern.filter { $0 == "#" }.count
	}

	// The active cell views
	private var cellViews: [Cell] = []

	// The string containing the current cell values
	private var currentValue: String = ""

	// The index of the cell that is currently editing
	private var currentlyEditingCellIndex: Int = 0
}

public extension DSFPasscodeView {
	override func prepareForInterfaceBuilder() {
		self.cellViews.forEach { $0.content = "0" }
	}

	override var intrinsicContentSize: NSSize {
		guard let templateCell = self.cellViews.first else { return .zero }
		let cs = templateCell.characterDimensions
		let h = cs.height + self.edgeInsets.top + self.edgeInsets.bottom
		var w: CGFloat = self.edgeInsets.left + self.edgeInsets.right
		self.pattern.enumerated().forEach { char in
			if char.1 == "#" {
				if char.0 != 0 {
					w += self.cellSpacing
				}
				w += cs.width
			}
			else if char.1 == "-" {
				w += self.groupSpacing
			}
		}
		return CGSize(width: w, height: h)
	}

	override func layout() {
		super.layout()

		guard let templateCell = self.cellViews.first else { return }
		let cs = templateCell.characterDimensions

		var cellOffset: Int = 0
		var xOffset: CGFloat = self.edgeInsets.left

		self.pattern.enumerated().forEach { char in
			if char.1 == "#" {
				let cell = self.cellViews[cellOffset]
				if char.0 != 0 {
					xOffset += self.cellSpacing
				}

				let newRect = NSRect(x: xOffset, y: self.edgeInsets.top, width: cs.width, height: cs.height)
				cell.frame = self.backingAlignedRect(newRect, options: [.alignAllEdgesInward])
				xOffset += cs.width

				cellOffset += 1
			}
			if char.1 == "-" {
				xOffset += self.groupSpacing
			}
		}
	}
}

public extension DSFPasscodeView {
	/// Reset the contents of the passcode view to empty
	func clear() {
		self.passcodeValue = nil
		self.cellViews.forEach {
			$0.content = ""
			$0.isEditable = false
		}
		self.currentlyEditingCellIndex = 0
		self.isEmpty = true
		if self.isEnabled {
			self.cellViews.first?.isEditable = true
			self.window?.makeFirstResponder(self.cellViews.first)
		}
	}
}

extension DSFPasscodeView {
	func setup() {
		self.translatesAutoresizingMaskIntoConstraints = true
		self.pattern = "###-###"
	}
}

// MARK: - First Responder handling

public extension DSFPasscodeView {
	override var acceptsFirstResponder: Bool {
		return self.isEnabled
	}

	override func becomeFirstResponder() -> Bool {
		if !self.isEnabled {
			return false
		}
		// Set the first responder to the currently editing cell
		if let index = self.cellViews.firstIndex(where: { cell in cell.content.count == 0 } )  {
			self.currentlyEditingCellIndex = index
			self.window?.makeFirstResponder(self.cellViews[index])
			return true
		}

		self.window?.makeFirstResponder(self.cellViews[self.currentlyEditingCellIndex])
		return true
	}

	internal func userClickedInactiveCell() {
		// User attempted to click a cell -- make sure we focus the currently editable field
		if self.isEnabled {
			self.window?.makeFirstResponder(self.cellViews[self.currentlyEditingCellIndex])
		}
	}
}

// MARK: - Accessibility

public extension DSFPasscodeView {
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

extension DSFPasscodeView {

	func removeAllCells() {
		self.cellViews.forEach { $0.removeFromSuperview() }
		self.cellViews = []
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
		self.removeAllCells()

		let newCount = self.pattern.filter { $0 == "#" }.count
		(0 ..< newCount).forEach { index in
			let r = Cell()
			r.font = self.font
			r.parent = self
			r.index = index
			r.setAccessibilityTitle(Localizations.PasscodeCharAccessibilityTitle(index: index + 1, total: self.passcodeCellCount))
			self.cellViews.append(r)
			self.addSubview(r)
		}

		self.currentlyEditingCellIndex = 0
		self.cellViews.first?.isEditable = true
	}
}

// MARK: - Handle cell events

internal extension DSFPasscodeView {

	// The cell update types
	enum UpdateType {
		case moveBack
		case moveForward
		case dontMove
		case clear
	}

	// Called when a cell updates its content
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

		if self.isEmpty != self.currentValue.isEmpty {
			self.isEmpty = self.currentValue.isEmpty
		}

		// Call the 'change' callback
		self.delegate?.passcodeViewDidChange?(self)

		// If we have a value which matches the pattern then tell the delegate
		if self.passcodeCellCount == self.currentValue.count {
			self.passcodeValue = self.currentValue
			self.delegate?.passcodeView?(self, validPasscodeValue: self.currentValue)
		}
		else {
			if self.passcodeValue != nil {
				self.passcodeValue = nil
			}
		}
	}

	func handleClear(_: Int) {
		self.clear()
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

	func notifyUserOfInvalidCharacter(ch: String?, index: Int) {
		self.delegate?.passcodeView?(self, didTryInvalidCharacter: ch, atIndex: index)
	}
}
