//
//  phistoryApp.swift
//  phistory
//
//  Created by wanghang on 2024/12/10.
//

import SwiftUI
import ServiceManagement

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 检查是否已经有实例在运行
        let runningApps = NSWorkspace.shared.runningApplications
        let isRunning = runningApps.filter { $0.bundleIdentifier == Bundle.main.bundleIdentifier }.count > 1
        
        if isRunning {
            NSApp.terminate(nil)
            return
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // 清理工作
    }
}

@main
struct phistoryApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var clipboardManager = ClipboardManager.shared
    @StateObject private var settingsManager = SettingsManager.shared
    @StateObject private var statusBarController: StatusBarController
    
    init() {
        let controller = StatusBarController()
        _statusBarController = StateObject(wrappedValue: controller)
    }
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
