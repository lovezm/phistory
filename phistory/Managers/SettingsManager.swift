import Foundation
import ServiceManagement
import SwiftUI

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @Published var launchAtLogin: Bool {
        didSet {
            setLaunchAtLogin(launchAtLogin)
        }
    }
    
    private init() {
        self.launchAtLogin = false
        if #available(macOS 13.0, *) {
            self.launchAtLogin = SMAppService.mainApp.status == .enabled
        } else {
            // 对于旧版本的 macOS，检查是否已经添加到登录项
            let apps = NSWorkspace.shared.runningApplications
            self.launchAtLogin = apps.contains { $0.bundleIdentifier == "com.ergou.phistory-launcher" }
        }
    }
    
    func setLaunchAtLogin(_ enable: Bool) {
        do {
            if #available(macOS 13.0, *) {
                if enable {
                    if SMAppService.mainApp.status == .enabled {
                        print("App is already registered for launch at login")
                        return
                    }
                    try SMAppService.mainApp.register()
                } else {
                    if SMAppService.mainApp.status == .notRegistered {
                        print("App is already not registered for launch at login")
                        return
                    }
                    try SMAppService.mainApp.unregister()
                }
            } else {
                let success = SMLoginItemSetEnabled("com.ergou.phistory" as CFString, enable)
                if !success {
                    print("Failed to \(enable ? "enable" : "disable") launch at login using legacy API")
                    return
                }
            }
            self.launchAtLogin = enable
            UserDefaults.standard.set(enable, forKey: "launchAtLogin")
        } catch {
            print("Failed to \(enable ? "enable" : "disable") launch at login: \(error)")
        }
    }
    
    func isLaunchAtLoginEnabled() -> Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        } else {
            return UserDefaults.standard.bool(forKey: "launchAtLogin")
        }
    }
}
