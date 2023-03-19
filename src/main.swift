#!/usr/bin/env swift
import ApplicationServices
import Cocoa
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
	private var statusItem: NSStatusItem!
	private var value: Float = 1.0

	func applicationDidFinishLaunching(_ aNotification: Notification) {
		UserDefaults.standard.register(defaults: ["value": 1.0])
		value = UserDefaults.standard.float(forKey: "value")
		updateGamma()
		// create status menu icon
		self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
		self.statusItem.button?.image = NSImage.statusIcon
		self.statusItem.menu = NSMenu(title: "")
		self.statusItem.menu!.addItem(sliderMenuItem())
		self.statusItem.menu!.addItem(NSMenuItem.separator())
		self.statusItem.menu!.addItem(withTitle: "Quit", action: #selector(NSApp.terminate), keyEquivalent: "q")
	}
	
	private func sliderMenuItem() -> NSMenuItem {
		let slider = NSSlider(frame: NSRect(x: 10, y: 5, width: 150, height: 0))
		slider.frame.size.height = slider.fittingSize.height
		slider.target = self
		slider.action = #selector(sliderCallback)
		slider.floatValue = value
		slider.numberOfTickMarks = 9
		slider.allowsTickMarkValuesOnly = true
		let item = NSMenuItem()
		item.view = NSView(frame: slider.frame.insetBy(dx: -10, dy: -5)) // add padding
		item.view!.addSubview(slider)
		return item
	}

	@objc
	private func sliderCallback(sender: NSSlider) {
		value = max(sender.floatValue, 0.1)  // safety measure, never get venta black
		UserDefaults.standard.setValue(value, forKey: "value")
		updateGamma()
	}
	
	private func updateGamma() {
		let table: [CGGammaValue] = [0, value]
		CGSetDisplayTransferByTable(CGMainDisplayID(), 2, table, table, table)
		
	}
}

// MARK: - Menu Bar Icon -

extension NSImage {
	static var statusIcon: NSImage {
		let img = NSImage(size: .init(width: 16, height: 16), flipped: true) { rect in
			let icon = UserDefaults.standard.integer(forKey: "icon")
			let w = min(rect.width, rect.height)
			let ctx = NSGraphicsContext.current!.cgContext
			// clip to circle
			ctx.addEllipse(in: rect)
			ctx.clip()
			// draw moon
			if icon == 0 || icon == 1 {
				ctx.addRect(rect)
				ctx.addEllipse(in: .init(x: 0.3 * w, y: -0.1 * w, width: 0.84 * w, height: 0.84 * w))
				ctx.fillPath(using: .evenOdd)
			}
			// draw stripes background
			if icon == 0 || icon == 2 {
				ctx.setFillColor(gray: 1.0, alpha: 0.2)
				ctx.addRect(rect); ctx.fillPath()
				ctx.addRect(rect.offsetBy(dx: 0, dy: 0.2 * rect.height)); ctx.fillPath()
				ctx.addRect(rect.offsetBy(dx: 0, dy: 0.45 * rect.height)); ctx.fillPath()
				ctx.addRect(rect.offsetBy(dx: 0, dy: 0.7 * rect.height)); ctx.fillPath()
			}
			return true
		}
		img.isTemplate = true
		return img
	}
}

// MARK: - Main Entry

let delegate = AppDelegate()
NSApplication.shared.delegate = delegate
NSApplication.shared.run()
// _ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
