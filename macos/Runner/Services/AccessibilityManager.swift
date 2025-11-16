import Cocoa
import ApplicationServices

/// Manages accessibility permissions required for controlling mouse and keyboard events
class AccessibilityManager {
    
    // MARK: - Singleton
    static let shared = AccessibilityManager()
    
    private init() {}
    
    // MARK: - Permission Checking
    
    /// Checks if the app has accessibility permissions
    /// - Returns: true if accessibility is trusted, false otherwise
    /// - Requirement: 10.1 - Check accessibility permission on startup
    func checkPermission() -> Bool {
        return AXIsProcessTrusted()
    }
    
    // MARK: - Permission Request
    
    /// Requests accessibility permission from the user
    /// This will show a system dialog prompting the user to grant permission
    /// - Requirement: 10.2 - Prompt user to open System Preferences if permission not granted
    func requestPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
    
    // MARK: - System Preferences
    
    /// Opens System Preferences to the Accessibility privacy settings
    /// - Requirement: 10.2 - Open System Preferences dialog
    func openSystemPreferences() {
        // macOS 13+ uses new Settings app URL scheme
        if #available(macOS 13.0, *) {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
        } else {
            // macOS 12 and earlier
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
        }
    }
    
    // MARK: - Permission Status Monitoring
    
    /// Checks permission status and shows alert if not granted
    /// - Returns: true if permission is granted, false otherwise
    /// - Requirement: 10.3 - Do not execute CGEvent API without permission
    func ensurePermission() -> Bool {
        if checkPermission() {
            return true
        } else {
            showPermissionAlert()
            return false
        }
    }
    
    // MARK: - User Interface
    
    /// Shows an alert dialog informing the user about missing accessibility permission
    /// - Requirement: 10.2 - Display dialog prompting user to grant permission
    private func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "Accessibility Permission Required"
        alert.informativeText = "RemoteTouch needs accessibility permission to control your mouse and keyboard. Please grant permission in System Preferences."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Preferences")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            openSystemPreferences()
        }
    }
    
    /// Shows a notification that permission is still required
    /// - Requirement: 10.2 - Inform user about permission requirement
    func showPermissionRequiredNotification() {
        let notification = NSUserNotification()
        notification.title = "Accessibility Permission Required"
        notification.informativeText = "RemoteTouch cannot function without accessibility permission. Please grant it in System Preferences."
        notification.soundName = NSUserNotificationDefaultSoundName
        
        NSUserNotificationCenter.default.deliver(notification)
    }
    
    // MARK: - Validation
    
    /// Validates that permission is granted before allowing event generation
    /// - Returns: true if events can be generated, false otherwise
    /// - Requirement: 10.3, 10.4 - Enable CGEvent API only when permission is granted
    func canGenerateEvents() -> Bool {
        let hasPermission = checkPermission()
        
        if !hasPermission {
            NSLog("AccessibilityManager: Cannot generate events - permission not granted")
        }
        
        return hasPermission
    }
}
