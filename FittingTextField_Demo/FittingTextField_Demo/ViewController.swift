//
//  ViewController.swift
//  FittingTextField_Demo
//
//  Created by usagimaru on 2021/05/14.
//

import Cocoa


class ViewController: NSViewController {
	
	@IBOutlet weak var textField: FittingTextField!

	override func viewDidLoad() {
		super.viewDidLoad()
		
		let clickRecognizer = NSClickGestureRecognizer(target: self, action: #selector(startTextEditing(_:)))
		clickRecognizer.numberOfClicksRequired = 2
		clickRecognizer.delegate = self
		self.textField.addGestureRecognizer(clickRecognizer)
		
		self.textField.delegate = self

		self.textField.wantsLayer = true
		self.textField.layer?.borderWidth = 1
		self.textField.layer?.borderColor = NSColor.red.withAlphaComponent(0.5).cgColor
	}
	
	@IBAction func startTextEditing(_ sender: Any) {
		self.textField.isEditable = true
		self.textField.becomeFirstResponder()
	}

}


// MARK: - NSTextFieldDelegate

extension ViewController: NSTextFieldDelegate {
	
	func controlTextDidEndEditing(_ notif: Notification) {
		if let textField = notif.object as? NSTextField, textField == self.textField {
			self.textField.isEditable = false
		}
	}
	
	func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
		// Dismiss focus
		if control == self.textField, commandSelector == #selector(cancelOperation(_:)) {
			self.view.window?.makeFirstResponder(self)
			return true
		}
		return false
	}
}


// MARK: - NSGestureRecognizerDelegate

extension ViewController: NSGestureRecognizerDelegate {
	
	func gestureRecognizer(_ gestureRecognizer: NSGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: NSGestureRecognizer) -> Bool {
		if case let gestureRecognizer as NSClickGestureRecognizer = gestureRecognizer, gestureRecognizer.numberOfClicksRequired == 2 {
			return true
		}
		
		return false
	}
	
}
