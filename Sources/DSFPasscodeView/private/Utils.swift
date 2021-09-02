//
//  Utilities.swift
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

#if os(macOS)

import AppKit

extension NSView {
	// Pin 'self' within 'other' view
	func pinEdges(to other: NSView, edgeInset: CGFloat = 0, animate: Bool = false) {
		self.pinEdges(to: other, edgeInsets: NSEdgeInsets(edgeInset: edgeInset), animate: animate)
	}

	// Pin 'self' within 'other' view
	func pinEdges(to other: NSView, edgeInsets: NSEdgeInsets, animate: Bool = false) {
		let target = animate ? animator() : self
		target.leadingAnchor.constraint(equalTo: other.leadingAnchor, constant: edgeInsets.left).isActive = true
		target.trailingAnchor.constraint(equalTo: other.trailingAnchor, constant: -edgeInsets.right).isActive = true
		target.topAnchor.constraint(equalTo: other.topAnchor, constant: edgeInsets.top).isActive = true
		target.bottomAnchor.constraint(equalTo: other.bottomAnchor, constant: -edgeInsets.bottom).isActive = true
	}
}

extension NSEdgeInsets {
	@inlinable init(edgeInset: CGFloat) {
		self.init(top: edgeInset, left: edgeInset, bottom: edgeInset, right: edgeInset)
	}
}

extension NSEdgeInsets: Equatable {
	@inlinable public static func == (lhs: NSEdgeInsets, rhs: NSEdgeInsets) -> Bool {
		return lhs.top == rhs.top &&
			lhs.bottom == rhs.bottom &&
			lhs.left == rhs.left &&
			lhs.right == rhs.right
	}
}

#endif
