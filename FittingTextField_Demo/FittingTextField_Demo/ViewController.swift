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
		
		textField.wantsLayer = true
		textField.layer?.borderWidth = 1
		textField.layer?.borderColor = NSColor.red.withAlphaComponent(0.5).cgColor
	}
		
	override func mouseDown(with event: NSEvent) {
		super.mouseDown(with: event)
		
		// End editing 
		if let locationInSuperview = textField.superview?.convert(event.locationInWindow, from: nil),
		   textField.frame.contains(locationInSuperview) == false {
			textField.unfocus(nil)
		}
	}

}
