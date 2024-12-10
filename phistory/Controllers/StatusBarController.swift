import Cocoa
import SwiftUI

class StatusBarController: ObservableObject {
    private var statusBar: NSStatusBar
    private var statusItem: NSStatusItem?
    private var popover: NSPopover
    private var eventMonitor: Any?
    private var mainWindow: NSWindow?
    
    init() {
        statusBar = NSStatusBar.system
        popover = NSPopover()
        
        let popoverView = HistoryView()
        
        popover.contentSize = NSSize(width: 360, height: 400)
        popover.behavior = .applicationDefined
        popover.contentViewController = NSHostingController(rootView: popoverView)
        
        // Add event monitor for clicks outside the popover
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self, self.popover.isShown else { return }
            
            // Get the mouse location in screen coordinates
            let mouseLocation = NSEvent.mouseLocation
            
            // Convert screen coordinates to window coordinates
            if let contentView = self.popover.contentViewController?.view,
               let window = contentView.window {
                let windowPoint = window.convertPoint(fromScreen: mouseLocation)
                
                // Check if click is outside the popover
                if !NSPointInRect(windowPoint, contentView.frame) {
                    self.popover.performClose(nil)
                }
            }
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.statusItem = self.statusBar.statusItem(withLength: NSStatusItem.squareLength)
            if let button = self.statusItem?.button {
                button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Clipboard History")?.withSymbolConfiguration(.init(scale: .medium))
                button.imagePosition = .imageOnly
                button.action = #selector(self.statusBarButtonClicked(_:))
                button.target = self
                button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            }
        }
    }
    
    deinit {
        if let eventMonitor = eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
        }
    }
    
    @objc func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        if popover.isShown {
            popover.performClose(sender)
        } else {
            if let button = statusItem?.button {
                NSApp.activate(ignoringOtherApps: true)
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                ClipboardManager.shared.loadRecentItems()
            }
        }
    }
    
    func openMainWindow() {
        if mainWindow == nil {
            let contentView = HistoryView()
            let hostingController = NSHostingController(rootView: contentView)
            
            mainWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 500, height: 600),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            
            mainWindow?.title = "Clipboard History"
            mainWindow?.contentViewController = hostingController
            mainWindow?.center()
            mainWindow?.setFrameAutosaveName("ClipboardHistoryWindow")
        }
        
        mainWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func showSettings() {
        let settingsView = SettingsView()
        let settingsPopover = NSPopover()
        settingsPopover.contentSize = NSSize(width: 300, height: 200)
        settingsPopover.behavior = .transient
        settingsPopover.contentViewController = NSHostingController(rootView: settingsView)
        
        if let button = statusItem?.button {
            settingsPopover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
}
