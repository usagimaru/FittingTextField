#if os(macOS)

import Cocoa

public class FittingTextField: NSTextField {
	
	public override var focusRingMaskBounds: NSRect {
		bounds
	}
	
	private var placeholderSize: NSSize? { didSet {
		if let placeholderSize_ = placeholderSize {
			placeholderSize = NSSize(width: ceil(placeholderSize_.width), height: ceil(placeholderSize_.height))
		}
	}}
	
	private var lastContentSize = NSSize() { didSet {
		lastContentSize = NSSize(width: ceil(lastContentSize.width), height: ceil(lastContentSize.height))
	}}
	
	public private(set) var isEditing = false
	
	public override var placeholderString: String? { didSet {
		guard let placeholderString = placeholderString else { return }
		placeholderSize = size(placeholderString)
	}}
	
	public override var stringValue: String { didSet {
		if isEditing {return}
		lastContentSize = size(stringValue)
	}}
	
	public private(set) var doubleClickRecognizer: NSClickGestureRecognizer!
	
	
	// MARK: -
	
	override init(frame frameRect: NSRect) {
		super.init(frame: frameRect)
		_init()
	}
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		_init()
	}
	
	private func _init() {
		// Receive text change notifications during Japanese input conversion (while `marked text` is present).
		(cell as? NSTextFieldCell)?.setWantsNotificationForMarkedText(true)
		
		// Setup double-click recognizer
		doubleClickRecognizer = NSClickGestureRecognizer(target: self, action: #selector(doubleClicked(_:)))
		doubleClickRecognizer.numberOfClicksRequired = 2
		doubleClickRecognizer.delaysPrimaryMouseButtonEvents = false
		doubleClickRecognizer.delegate = self
		addGestureRecognizer(doubleClickRecognizer)
		
		#if DEBUG
		//wantsLayer = true
		//layer?.setBorder(with: NSColor.red.cgColor)
		#endif
	}
	
	public override func awakeFromNib() {
		super.awakeFromNib()
		
		// If you use `.byClipping`, the width calculation does not seem to be done correctly.
		cell?.isScrollable = true
		cell?.wraps = true
		lineBreakMode = .byTruncatingTail
		
		lastContentSize = size(stringValue)
		if let placeholderString = placeholderString {
			placeholderSize = size(placeholderString)
		}
	}
	
	private func size(_ string: String) -> NSSize {
		let font = font ?? NSFont.systemFont(ofSize: NSFont.systemFontSize, weight: .regular)
		let stringSize = NSAttributedString(string: string, attributes: [.font : font]).size()
		
		return NSSize(width: stringSize.width, height: super.intrinsicContentSize.height)
	}
	
	public override var intrinsicContentSize: NSSize {
		let intrinsicContentSize = super.intrinsicContentSize
		
		let minWidth = (stringValue.isEmpty == false)
		? lastContentSize.width
		: ceil(placeholderSize?.width ?? 0)
		
		let minSize = NSSize(width: minWidth, height: intrinsicContentSize.height)
				
		guard let fieldEditor = currentEditor() as? NSTextView
		else { return minSize }
		
		if !isEditing {
			return minSize
		}
		
		if fieldEditor.string.isEmpty {
			lastContentSize = minSize
			return minSize
		}
		
		let newWidth = ceil(size(stringValue).width)
		let newSize = NSSize(width: newWidth, height: intrinsicContentSize.height)
		
		lastContentSize = newSize
		
		// This is a tweak to fix the problem of insertion points being drawn at the wrong position.
		fieldEditor.fixInsertionPointDisplaying()
		
		return newSize
	}
	
	
	// MARK: - Events
	
	/*
	 Triggers to begin editing:
	 - Double click
	 - Force click
	 - Becomes first responder
	 - When focus() is called explicitly
	 
	 Triggers to end editing:
	 - Received Return key event or editing successfully completed
	 - Received cancelOperation() events
	 - Received Tab key event (the focus is switched to another control)
	 - Resigns first responder
	 - When unfocus() is called explicitly
	 - Other reasons
	 */
	
	public override func textDidBeginEditing(_ notification: Notification) {
		super.textDidBeginEditing(notification)
		
		isEditing = true
		
		// This is a tweak to fix the problem of insertion points being drawn at the wrong position.
		if let fieldEditor = currentEditor() as? NSTextView {
			fieldEditor.clearInsertionPoint()
		}
	}
	
	public override func textDidEndEditing(_ notification: Notification) {
		super.textDidEndEditing(notification)
		
		// Hmm... synchronous execution will not get out of the edit state properly, so make it asynchronous.
		DispatchQueue.main.async {
			self.isEditing = false
			self.isEditable = false
			self.window?.makeFirstResponder(nil)
			
			// Reset the cursor rects of own text field. (Prevent displaying an I-bean cursor when the control is not editable)
			self.window?.invalidateCursorRects(for: self)
		}
	}
	
	public override func textDidChange(_ notification: Notification) {
		super.textDidChange(notification)
		invalidateIntrinsicContentSize()
	}
	
	@objc public func doubleClicked(_ sender: NSClickGestureRecognizer) {
		focus(self)
	}
	
	public override func cancelOperation(_ sender: Any?) {
		unfocus(self)
	}
	
	/// Detect force touch event (Trackpad only)
	public override func pressureChange(with event: NSEvent) {
		super.pressureChange(with: event)
		
		if event.stage == 2 {
			// Ref: WWDC15 217 - Adopting New Trackpad Features
			// 0 = gesture release
			// 1 = click
			// 2 = force click
			
			// Begin editing when the control is receiving force touch event
			if isEditing == false {
				focus(self)
			}
		}
	}
	
	
	// MARK: -
	
	@objc public func focus(_ sender: Any?) {
		isEditable = true
		isEditing = true
		window?.makeFirstResponder(self)
	}
	
	@objc public func unfocus(_ sender: Any?) {
		if let fieldEditor = currentEditor() {
			endEditing(fieldEditor)
		}
	}
	
}


// MARK: - NSGestureRecognizerDelegate

extension FittingTextField: NSGestureRecognizerDelegate {
	
	public func gestureRecognizer(_ gestureRecognizer: NSGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: NSGestureRecognizer) -> Bool {
		if let gestureRecognizer = gestureRecognizer as? NSClickGestureRecognizer, gestureRecognizer.numberOfClicksRequired == 2 {
			return true
		}
		return false
	}
	
}

extension NSTextView {
	
	/// This is a tweak to fix the problem of insertion points being drawn at the wrong position.
	func fixInsertionPointDisplaying() {
		insertionPointColor = textColor ?? NSColor.textColor
	}
	
	func clearInsertionPoint() {
		insertionPointColor = NSColor.clear
	}
	
}

#endif
