//
//  ApplicationController.swift
//  RemoteTouch macOS
//
//  Main application controller that coordinates BLE, command processing, and UI
//

import Cocoa

/// Main application controller
class ApplicationController: NSObject {
    
    // MARK: - Singleton
    
    static let shared = ApplicationController()
    
    // MARK: - Properties
    
    private let bleManager: BLEPeripheralManager
    private let commandProcessor: CommandProcessor
    private let pairingWindowController: PairingWindowController
    private let accessibilityManager = AccessibilityManager.shared
    
    // Menu bar
    private var statusItem: NSStatusItem?
    private var statusMenu: NSMenu?
    
    // MARK: - Initialization
    
    private override init() {
        self.bleManager = BLEPeripheralManager()
        self.commandProcessor = CommandProcessor()
        self.pairingWindowController = PairingWindowController()
        
        super.init()
        
        setupBLEManager()
        setupMenuBar()
        checkAccessibilityPermission()
    }
    
    // MARK: - Setup
    
    private func setupBLEManager() {
        bleManager.delegate = self
    }
    
    private func setupMenuBar() {
        // Create status item in menu bar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "antenna.radiowaves.left.and.right", accessibilityDescription: "RemoteTouch")
            button.toolTip = "RemoteTouch"
        }
        
        // Create menu
        statusMenu = NSMenu()
        statusMenu?.delegate = self
        
        // Title
        let titleItem = NSMenuItem(title: "RemoteTouch", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        statusMenu?.addItem(titleItem)
        statusMenu?.addItem(NSMenuItem.separator())
        
        // Connection status
        let connectionItem = NSMenuItem(title: "Status: Disconnected", action: nil, keyEquivalent: "")
        connectionItem.tag = 100 // Tag for easy access
        connectionItem.isEnabled = false
        statusMenu?.addItem(connectionItem)
        
        statusMenu?.addItem(NSMenuItem.separator())
        
        // Pairing code
        let pairingItem = NSMenuItem(title: "Show Pairing Code", action: #selector(showPairingCode), keyEquivalent: "p")
        pairingItem.target = self
        statusMenu?.addItem(pairingItem)
        
        statusMenu?.addItem(NSMenuItem.separator())
        
        // Accessibility permission
        let accessibilityItem = NSMenuItem(title: "Check Accessibility Permission", action: #selector(checkAccessibilityPermissionMenu), keyEquivalent: "a")
        accessibilityItem.tag = 101
        accessibilityItem.target = self
        statusMenu?.addItem(accessibilityItem)
        
        statusMenu?.addItem(NSMenuItem.separator())
        
        // Quit
        let quitItem = NSMenuItem(title: "Quit RemoteTouch", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        statusMenu?.addItem(quitItem)
        
        statusItem?.menu = statusMenu
    }
    
    private func checkAccessibilityPermission() {
        if !accessibilityManager.checkPermission() {
            // Show alert about accessibility permission
            DispatchQueue.main.async { [weak self] in
                self?.showAccessibilityAlert()
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Start the application
    func start() {
        NSLog("ApplicationController: Starting RemoteTouch")
        bleManager.startAdvertising()
        updateMenuBarStatus()
    }
    
    /// Stop the application
    func stop() {
        NSLog("ApplicationController: Stopping RemoteTouch")
        bleManager.stopAdvertising()
    }
    
    // MARK: - Menu Actions
    
    @objc private func showPairingCode() {
        if let code = bleManager.getCurrentPairingCode() {
            pairingWindowController.showPairingCode(code)
        } else {
            // Generate new pairing code by triggering a pairing request
            // This would normally happen when iOS device connects
            NSLog("ApplicationController: No active pairing code")
            
            let alert = NSAlert()
            alert.messageText = "No Pairing Request"
            alert.informativeText = "Wait for an iOS device to request pairing, or ensure Bluetooth is enabled."
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
    
    @objc private func checkAccessibilityPermissionMenu() {
        if accessibilityManager.checkPermission() {
            let alert = NSAlert()
            alert.messageText = "Accessibility Permission Granted"
            alert.informativeText = "RemoteTouch has the necessary permissions to control your Mac."
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.runModal()
        } else {
            showAccessibilityAlert()
        }
    }
    
    @objc private func quit() {
        stop()
        NSApplication.shared.terminate(nil)
    }
    
    // MARK: - Private Methods
    
    private func updateMenuBarStatus() {
        guard let menu = statusMenu else { return }
        
        // Update menu bar icon based on connection state
        if let button = statusItem?.button {
            if bleManager.isConnected {
                button.image = NSImage(systemSymbolName: "antenna.radiowaves.left.and.right.circle.fill", accessibilityDescription: "RemoteTouch Connected")
                button.toolTip = "RemoteTouch - Connected"
            } else if bleManager.isAdvertising {
                button.image = NSImage(systemSymbolName: "antenna.radiowaves.left.and.right", accessibilityDescription: "RemoteTouch Advertising")
                button.toolTip = "RemoteTouch - Advertising"
            } else {
                button.image = NSImage(systemSymbolName: "antenna.radiowaves.left.and.right.slash", accessibilityDescription: "RemoteTouch Disconnected")
                button.toolTip = "RemoteTouch - Disconnected"
            }
        }
        
        // Update connection status
        if let connectionItem = menu.item(withTag: 100) {
            if bleManager.isConnected {
                connectionItem.title = "Status: ✓ Connected"
            } else if bleManager.isAdvertising {
                connectionItem.title = "Status: ⚡ Advertising"
            } else {
                connectionItem.title = "Status: ⚫ Disconnected"
            }
        }
        
        // Update accessibility status
        if let accessibilityItem = menu.item(withTag: 101) {
            if accessibilityManager.checkPermission() {
                accessibilityItem.title = "✓ Accessibility Permission Granted"
            } else {
                accessibilityItem.title = "⚠️ Accessibility Permission Required"
            }
        }
    }
    
    private func showAccessibilityAlert() {
        let alert = NSAlert()
        alert.messageText = "Accessibility Permission Required"
        alert.informativeText = "RemoteTouch needs accessibility permission to control your Mac's cursor and keyboard. Click 'Open System Preferences' to grant permission."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Preferences")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            accessibilityManager.openSystemPreferences()
        }
    }
}

// MARK: - NSMenuDelegate

extension ApplicationController: NSMenuDelegate {
    
    func menuWillOpen(_ menu: NSMenu) {
        // Update menu items when menu is about to open
        updateMenuBarStatus()
    }
}

// MARK: - BLEPeripheralManagerDelegate

extension ApplicationController: BLEPeripheralManagerDelegate {
    
    func peripheralManager(_ manager: BLEPeripheralManager, didReceiveCommand command: Any) {
        // Process the command through the command processor
        commandProcessor.processCommand(command)
    }
    
    func peripheralManager(_ manager: BLEPeripheralManager, didUpdateConnectionState isConnected: Bool) {
        NSLog("ApplicationController: Connection state changed - \(isConnected ? "Connected" : "Disconnected")")
        updateMenuBarStatus()
    }
    
    func peripheralManager(_ manager: BLEPeripheralManager, didGeneratePairingCode code: String) {
        NSLog("ApplicationController: Pairing code generated - \(code)")
        pairingWindowController.showPairingCode(code)
    }
    
    func peripheralManager(_ manager: BLEPeripheralManager, didCompletePairingWith device: Device) {
        NSLog("ApplicationController: Pairing completed with device - \(device.name)")
        pairingWindowController.showPairingSuccess(deviceName: device.name)
    }
    
    func peripheralManager(_ manager: BLEPeripheralManager, didFailPairingWithError error: PairingError) {
        NSLog("ApplicationController: Pairing failed - \(error.localizedDescription)")
        
        switch error {
        case .invalidCode:
            pairingWindowController.showPairingFailure(error: "Invalid pairing code")
        case .timeout:
            pairingWindowController.showPairingFailure(error: "Pairing timeout")
        case .lockedOut(let remainingTime):
            let seconds = Int(remainingTime)
            pairingWindowController.showLockout(remainingSeconds: seconds)
        case .alreadyPaired:
            pairingWindowController.showPairingFailure(error: "Device already paired")
        case .maxDevicesReached:
            pairingWindowController.showPairingFailure(error: "Maximum devices reached")
        case .storageError:
            pairingWindowController.showPairingFailure(error: "Storage error")
        }
    }
}
