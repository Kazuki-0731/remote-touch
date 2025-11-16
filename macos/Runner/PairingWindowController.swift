//
//  PairingWindowController.swift
//  RemoteTouch macOS
//
//  Window controller for displaying pairing code
//

import Cocoa

/// Window controller that displays the pairing code to the user
class PairingWindowController: NSWindowController {
    
    // MARK: - UI Elements
    
    private let codeLabel: NSTextField = {
        let label = NSTextField(labelWithString: "")
        label.font = NSFont.systemFont(ofSize: 48, weight: .bold)
        label.alignment = .center
        label.textColor = .labelColor
        return label
    }()
    
    private let instructionLabel: NSTextField = {
        let label = NSTextField(labelWithString: "Enter this code on your iPhone to pair")
        label.font = NSFont.systemFont(ofSize: 14)
        label.alignment = .center
        label.textColor = .secondaryLabelColor
        return label
    }()
    
    private let titleLabel: NSTextField = {
        let label = NSTextField(labelWithString: "Pairing Code")
        label.font = NSFont.systemFont(ofSize: 18, weight: .semibold)
        label.alignment = .center
        label.textColor = .labelColor
        return label
    }()
    
    private let statusLabel: NSTextField = {
        let label = NSTextField(labelWithString: "Waiting for pairing...")
        label.font = NSFont.systemFont(ofSize: 12)
        label.alignment = .center
        label.textColor = .tertiaryLabelColor
        return label
    }()
    
    private let progressIndicator: NSProgressIndicator = {
        let indicator = NSProgressIndicator()
        indicator.style = .spinning
        indicator.controlSize = .small
        indicator.isDisplayedWhenStopped = false
        return indicator
    }()
    
    private let closeButton: NSButton = {
        let button = NSButton(title: "Cancel", target: nil, action: nil)
        button.bezelStyle = .rounded
        return button
    }()
    
    // MARK: - Properties
    
    private var currentCode: String = ""
    
    // MARK: - Initialization
    
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "RemoteTouch Pairing"
        window.center()
        window.isReleasedWhenClosed = false
        
        self.init(window: window)
        setupUI()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        guard let contentView = window?.contentView else { return }
        
        // Create container view
        let containerView = NSView(frame: contentView.bounds)
        containerView.autoresizingMask = [.width, .height]
        contentView.addSubview(containerView)
        
        // Add subviews
        containerView.addSubview(titleLabel)
        containerView.addSubview(codeLabel)
        containerView.addSubview(instructionLabel)
        containerView.addSubview(statusLabel)
        containerView.addSubview(progressIndicator)
        containerView.addSubview(closeButton)
        
        // Disable autoresizing masks
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        codeLabel.translatesAutoresizingMaskIntoConstraints = false
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        progressIndicator.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Setup constraints
        NSLayoutConstraint.activate([
            // Title
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 30),
            titleLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            titleLabel.widthAnchor.constraint(equalTo: containerView.widthAnchor, constant: -40),
            
            // Code
            codeLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            codeLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor, constant: -10),
            codeLabel.widthAnchor.constraint(equalTo: containerView.widthAnchor, constant: -40),
            
            // Instruction
            instructionLabel.topAnchor.constraint(equalTo: codeLabel.bottomAnchor, constant: 20),
            instructionLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            instructionLabel.widthAnchor.constraint(equalTo: containerView.widthAnchor, constant: -40),
            
            // Status
            statusLabel.topAnchor.constraint(equalTo: instructionLabel.bottomAnchor, constant: 10),
            statusLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            statusLabel.widthAnchor.constraint(equalTo: containerView.widthAnchor, constant: -40),
            
            // Progress indicator
            progressIndicator.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 10),
            progressIndicator.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            
            // Close button
            closeButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20),
            closeButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 100)
        ])
        
        // Setup button action
        closeButton.target = self
        closeButton.action = #selector(closeWindow)
    }
    
    // MARK: - Public Methods
    
    /// Display the pairing code
    func showPairingCode(_ code: String) {
        currentCode = code
        
        // Format code with spaces for readability (e.g., "123 456")
        let formattedCode = formatCode(code)
        codeLabel.stringValue = formattedCode
        statusLabel.stringValue = "Waiting for pairing..."
        statusLabel.textColor = .tertiaryLabelColor
        
        // Show progress indicator
        progressIndicator.startAnimation(nil)
        
        // Reset button
        closeButton.title = "Cancel"
        closeButton.isEnabled = true
        
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    /// Show pairing success
    func showPairingSuccess(deviceName: String) {
        statusLabel.stringValue = "✓ Paired with \(deviceName)"
        statusLabel.textColor = .systemGreen
        
        // Stop progress indicator
        progressIndicator.stopAnimation(nil)
        
        // Update button
        closeButton.title = "Close"
        
        // Auto-close after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.closeWindow()
        }
    }
    
    /// Show pairing failure
    func showPairingFailure(error: String) {
        statusLabel.stringValue = "✗ \(error)"
        statusLabel.textColor = .systemRed
        
        // Stop progress indicator
        progressIndicator.stopAnimation(nil)
        
        // Update button
        closeButton.title = "Close"
    }
    
    /// Show lockout message
    func showLockout(remainingSeconds: Int) {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        statusLabel.stringValue = "⚠️ Locked out. Try again in \(minutes)m \(seconds)s"
        statusLabel.textColor = .systemOrange
        codeLabel.stringValue = "---"
        
        // Stop progress indicator
        progressIndicator.stopAnimation(nil)
        
        // Update button
        closeButton.title = "Close"
    }
    
    /// Hide the pairing window
    @objc func closeWindow() {
        // Stop progress indicator
        progressIndicator.stopAnimation(nil)
        
        window?.orderOut(nil)
    }
    
    // MARK: - Private Methods
    
    private func formatCode(_ code: String) -> String {
        guard code.count == 6 else { return code }
        
        let firstPart = String(code.prefix(3))
        let secondPart = String(code.suffix(3))
        return "\(firstPart) \(secondPart)"
    }
}
