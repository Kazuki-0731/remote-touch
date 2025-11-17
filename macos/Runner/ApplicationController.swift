//
//  ApplicationController.swift
//  RemoteTouch macOS
//
//  Main application controller that coordinates BLE, command processing, and UI
//

import Cocoa
import CoreBluetooth

/// Main application controller
class ApplicationController: NSObject {
    
    // MARK: - Singleton
    
    static let shared = ApplicationController()
    
    // MARK: - Properties

    private let bleManager: BLECentralManager
    private let commandProcessor: CommandProcessor
    private let pairingWindowController: PairingWindowController
    private let accessibilityManager = AccessibilityManager.shared

    // Menu bar
    private var statusItem: NSStatusItem?
    private var statusMenu: NSMenu?

    // Discovered peripherals
    private var discoveredPeripherals: [CBPeripheral] = []

    // MARK: - Initialization

    private override init() {
        self.bleManager = BLECentralManager()
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
        NSLog("ApplicationController: setupMenuBar() called")

        // Create status item in menu bar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        NSLog("ApplicationController: statusItem created: \(statusItem != nil)")

        if let button = statusItem?.button {
            NSLog("ApplicationController: statusItem.button exists")
            if #available(macOS 11.0, *) {
                button.image = NSImage(systemSymbolName: "antenna.radiowaves.left.and.right", accessibilityDescription: "RemoteTouch")
                NSLog("ApplicationController: Set system symbol image")
            } else {
                button.title = "RT"
                NSLog("ApplicationController: Set text title 'RT'")
            }
            button.toolTip = "RemoteTouch"
        } else {
            NSLog("ApplicationController: ERROR - statusItem.button is nil")
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
        
        // Connection status
        let connectionStatusItem = NSMenuItem(title: "Show Connection Status", action: #selector(showPairingCode), keyEquivalent: "c")
        connectionStatusItem.target = self
        statusMenu?.addItem(connectionStatusItem)
        
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
        bleManager.startScanning()
        updateMenuBarStatus()
    }

    /// Stop the application
    func stop() {
        NSLog("ApplicationController: Stopping RemoteTouch")
        bleManager.stopScanning()
        bleManager.disconnect()
    }
    
    // MARK: - Menu Actions
    
    @objc private func showPairingCode() {
        // In Central mode, we don't generate pairing codes
        // Instead, show connection status
        let alert = NSAlert()

        if bleManager.isConnected {
            alert.messageText = "Connected"
            alert.informativeText = "RemoteTouch is connected to a mobile device."
        } else if bleManager.isScanning {
            alert.messageText = "Scanning"
            alert.informativeText = "Scanning for mobile devices. Please ensure the RemoteTouch app is running on your mobile device and advertising."
        } else {
            alert.messageText = "Not Scanning"
            alert.informativeText = "RemoteTouch is not currently scanning. Restart the app to begin scanning."
        }

        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
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
            if #available(macOS 11.0, *) {
                if bleManager.isConnected {
                    button.image = NSImage(systemSymbolName: "antenna.radiowaves.left.and.right.circle.fill", accessibilityDescription: "RemoteTouch Connected")
                    button.toolTip = "RemoteTouch - Connected"
                } else if bleManager.isScanning {
                    button.image = NSImage(systemSymbolName: "antenna.radiowaves.left.and.right", accessibilityDescription: "RemoteTouch Scanning")
                    button.toolTip = "RemoteTouch - Scanning"
                } else {
                    button.image = NSImage(systemSymbolName: "antenna.radiowaves.left.and.right.slash", accessibilityDescription: "RemoteTouch Disconnected")
                    button.toolTip = "RemoteTouch - Disconnected"
                }
            } else {
                if bleManager.isConnected {
                    button.title = "RT●"
                    button.toolTip = "RemoteTouch - Connected"
                } else if bleManager.isScanning {
                    button.title = "RT"
                    button.toolTip = "RemoteTouch - Scanning"
                } else {
                    button.title = "RT○"
                    button.toolTip = "RemoteTouch - Disconnected"
                }
            }
        }

        // Update connection status
        if let connectionItem = menu.item(withTag: 100) {
            if bleManager.isConnected {
                connectionItem.title = "Status: ✓ Connected"
            } else if bleManager.isScanning {
                connectionItem.title = "Status: 🔍 Scanning"
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

// MARK: - BLECentralManagerDelegate

extension ApplicationController: BLECentralManagerDelegate {

    func centralManager(_ manager: BLECentralManager, didReceiveCommand command: Any) {
        // Process the command through the command processor
        commandProcessor.processCommand(command)
    }

    func centralManager(_ manager: BLECentralManager, didUpdateConnectionState isConnected: Bool) {
        NSLog("ApplicationController: Connection state changed - \(isConnected ? "Connected" : "Disconnected")")
        updateMenuBarStatus()
    }

    func centralManager(_ manager: BLECentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String: Any]) {
        NSLog("ApplicationController: Discovered peripheral - \(peripheral.name ?? "Unknown")")

        // Add to discovered list if not already present
        if !discoveredPeripherals.contains(where: { $0.identifier == peripheral.identifier }) {
            discoveredPeripherals.append(peripheral)

            // Auto-connect to first discovered peripheral
            if discoveredPeripherals.count == 1 {
                NSLog("ApplicationController: Auto-connecting to first peripheral")
                bleManager.connect(to: peripheral)
            }
        }
    }
}
