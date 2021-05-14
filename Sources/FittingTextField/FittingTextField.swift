#if os(macOS)

import Cocoa

public class FittingTextField: NSTextField {
	
	private(set) var isEditing = false
	
	private var placeholderSize: NSSize?
	private var lastContentSize: NSSize?
	
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
		(self.cell as? NSTextFieldCell)?.setWantsNotificationForMarkedText(true)			
				
		#if DEBUG
		//self.wantsLayer = true
		//self.layer?.setBorder(with: NSColor.red.cgColor)
		#endif
	}
	
	public override func awakeFromNib() {
		super.awakeFromNib()
		
		// If you use `.byClipping`, the width calculation does not seem to be done correctly.
		self.cell?.isScrollable = true
		self.cell?.wraps = true
		self.lineBreakMode = .byTruncatingTail
		
		if let placeholderString = self.placeholderString {
			self.placeholderSize = size(placeholderString)
		}
	}
	
	public override var placeholderString: String? { didSet {
		guard let placeholderString = self.placeholderString else { return }
		self.placeholderSize = size(placeholderString)
	}}
	
	public override var stringValue: String { didSet {
		if self.isEditing {return}
		self.lastContentSize = size(stringValue)
	}}
	
	private func size(_ string: String) -> NSSize {
		let font = self.font ?? NSFont.systemFont(ofSize: NSFont.systemFontSize, weight: .regular)
		let stringSize = NSAttributedString(string: string, attributes: [.font : font]).size()
		
		return NSSize(width: stringSize.width, height: super.intrinsicContentSize.height)
	}
	
	public override func textDidBeginEditing(_ notification: Notification) {
		super.textDidBeginEditing(notification)
		self.isEditing = true
		
		// This is a tweak to fix the problem of insertion points being drawn at the wrong position.
		if let fieldEditor = self.window?.fieldEditor(false, for: self) as? NSTextView {
			fieldEditor.insertionPointColor = NSColor.clear
		}
	}
	
	public override func textDidEndEditing(_ notification: Notification) {
		super.textDidEndEditing(notification)
		self.isEditing = false
	}
	
	public override func textDidChange(_ notification: Notification) {
		super.textDidChange(notification)
		self.invalidateIntrinsicContentSize()
	}
	
	public override var intrinsicContentSize: NSSize {
		let intrinsicContentSize = super.intrinsicContentSize
		let minSize = NSSize(width: ceil(self.placeholderSize?.width ?? 0), height: intrinsicContentSize.height)
		
		guard let fieldEditor = self.window?.fieldEditor(false, for: self) as? NSTextView
		else {
			return self.lastContentSize ?? minSize
		}
		
		if !self.isEditing {
			return self.lastContentSize ?? minSize
		}
		
		if fieldEditor.string.isEmpty {
			self.lastContentSize = minSize
			return minSize
		}
		
		
		// This is a tweak to fix the problem of insertion points being drawn at the wrong position.
		fieldEditor.insertionPointColor = self.textColor ?? NSColor.textColor
		
		let newWidth = ceil(size(self.stringValue).width)
		let newSize = NSSize(width: newWidth, height: intrinsicContentSize.height)
		
		self.lastContentSize = newSize
		
		return newSize
	}
	
}

#endif
