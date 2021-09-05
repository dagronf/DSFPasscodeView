# DSFPasscodeView

A passcode entry field for macOS similar to Apple's two-factor authentication field.

<p align="center">
   <img src="https://github.com/dagronf/dagronf.github.io/blob/master/art/projects/DSFPasscodeView/dark-mode.gif?raw=true" />
   <br><br>
   <img src="https://github.com/dagronf/dagronf.github.io/blob/master/art/projects/DSFPasscodeView/light-mode.gif?raw=true" />
</p>

<p align="center">
    <img src="https://img.shields.io/github/v/tag/dagronf/DSFPasscodeView" />
    <img src="https://img.shields.io/badge/macOS-10.11+-blue" />
    <img src="https://img.shields.io/badge/Xcode-12+-yellow" />
    <img src="https://img.shields.io/badge/Swift-5.1-orange.svg" />
    <img src="https://img.shields.io/badge/License-MIT-lightgrey" />
    <a href="https://swift.org/package-manager">
        <img src="https://img.shields.io/badge/spm-compatible-brightgreen.svg?style=flat" alt="Swift Package Manager" />
    </a>
</p>


## About

The control is made up of multiple groups of passcode 'cells'. Each cell holds a single 'character', and you define groups of cells using a group separator. The pattern you define provides the layout -- containing `#` for a passcode cell and `-` for a group separator.

For example, to create a passcode of six characters split evenly into two groups of three cells, you set the passcode pattern to `"###-###"`

```
.---. .---. .---.   .---. .---. .---.
|   | |   | |   |   |   | |   | |   |
|   | |   | |   |   |   | |   | |   |
`---' `---' `---'   `---' `---' `---'
```

This control can be used in both autolayout and manual layout apps (internally the control does not use auto-layout)

Note this control uses [@VIViewInvalidating](https://github.com/dagronf/VIViewInvalidating) providing automatic NSView invalidation when properties value change. (automatically added as a dependency)

## Features

* Configurable allowable character support
* Character Viewer support (eg. hit Command-Ctrl-Space when a passcode cell is active)
* Different fonts
* Different spacing (intra-cell, edge insets, group and cell spacing)
* Light and dark modes
* High contrast support
* Accessibility and VoiceOver support

## Installation

Using Swift Package Manager, add `https://github.com/dagronf/DSFPasscodeView` to your project.

## Settings

### pattern (`String`)

The cell pattern to use when displaying the passcode. A `#` represents a cell and a `-` represents a group space. 

The only valid characters are # (a cell) and - (group spacing). Attempting to set a pattern with any other character will result in a `fatalError()`

Examples :-

```
"###-###"
.---. .---. .---.   .---. .---. .---.
|   | |   | |   |   |   | |   | |   |
|   | |   | |   |   |   | |   | |   |
`---' `---' `---'   `---' `---' `---'

"####-##-###"
.---. .---. .---. .---.   .---. .---.   .---. .---. .---.
|   | |   | |   | |   |   |   | |   |   |   | |   | |   |
|   | |   | |   | |   |   |   | |   |   |   | |   | |   |
`---' `---' `---' `---'   `---' `---'   `---' `---' `---'

"##-##-#"
.---. .---.   .---. .---.   .---.
|   | |   |   |   | |   |   |   |
|   | |   |   |   | |   |   |   |
`---' `---'   `---' `---'   `---'
```

### cellSpacing (`CGFloat`)

The spacing to use between adjacent cells

### groupSpacing (`CGFloat`)

The spacing to use between cell groups

### font (`NSFont`)

The font to use when displaying the character in a cell

### padding (`CGSize`)

The padding to use between the character and the edge of its cell

### edgeInsets (`NSEdgeInsets`)

The padding to use between the cells and the bounds of the control

### isEnabled (`Bool`)

Enable or disable the control (observable)

## Validations

There are two methods of validation

### allowableCharacters (String)

This settings on the control allows you to specify a string containing the characters that are allowed within the control. By default, this is `0123456789`.

### characterValidatorBlock 

For more complex validations, you can specify a callback block which can be used to validate each character

It takes a string element and returns either a value transformed string element (for example, uppercased), or nil if the presented character isn't valid for the control.
 
```swift
// A validator block which allows numbers and case-insensitive A-F characters
self.passcode.characterValidatorBlock = { element in
   let validChars = "0123456789ABCDEF"
   let s = element.uppercased()         // Always check against uppercase
   if validChars.contains(s) {          // If the validChars contains the uppercased char...
       return s.first                   //  ... return the uppercased version
   }
   return nil                           // Unsupported char, ignore by returning nil
}
```

## Values

You can bind to these member variables to receive updates as the control content changes.

### isValidPasscode (`Bool`)

Is the passcode entered a valid passcode (ie. all the values are specified)

### isEmpty (`Bool`)

Are there no values specified yet

### passcodeValue (`String`)

If the passcode is valid, the passcode value as a string, otherwise nil.

## Delegate (DSFPasscodeViewHandling)

You can attach a delegate to receive messages back from the view if binding is not your thing.

```swift
func passcodeViewDidChange(
   _ view: DSFPasscodeView)
```

Called when the content of the passcode view changes.

```swift
func passcodeView(
   _ view: DSFPasscodeView,                        // The passcode view
   updatedPasscodeValue passcode: String)          // The valid passcode as a string of characters
```

Called ONLY when the passcode is valid and complete.

```swift
func passcodeView(
   _ view: DSFPasscodeView,                        // The passcode view 
   didTryInvalidCharacter invalidChar: String?,    // The invalid character, or nil for a special key
   atIndex index: Int)                             // The passcode cell index where the attempt failed
```

Called if the user presses an unsupported character or key in a passcode cell.

## Known issues

* Xcode has been broken for many years regarding support for `@IBDesignable`/`@IBInspectable`. Whilst this control provides support, Xcode's support for @IBDesignable for a control provided from a package is completely broken.  

If you copy the DSFPasscodeView source files directly into your project the Designables work as expected (FB8358478).

## License

MIT. Use it and abuse it for anything you want, just attribute my work. Let me know if you do use it somewhere, I'd love to hear about it!

```
MIT License

Copyright (c) 2021 Darren Ford

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
