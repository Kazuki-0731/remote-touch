//
//  E2EIntegrationTests.swift
//  RemoteTouch macOS E2E Integration Tests
//
//  End-to-end integration tests for the complete system flow
//

import XCTest
import CoreGraphics
import CoreBluetooth
@testable import Runner

class E2EIntegrationTests: XCTestCase {
    
    var blePeripheralManager: MockBLEPeripheralManager!
    var commandProcessor: CommandProcessor!
    var eventGenerator: MockEventGenerator!
    var pairingManager: PairingManager!
    
    override func setUp() {
        super.setUp()
        eventGenerator = MockEventGenerator()
        commandProcessor = CommandProcessor(eventGenerator: eventGenerator)
        blePeripheralManager = MockBLEPeripheralManager()
        pairingManager = PairingManager()
    }
    
    override func tearDown() {
        blePeripheralManager = nil
        commandProcessor = nil
        eventGenerator = nil
        pairingManager = nil
        super.tearDown()
    }
    
    // MARK: - E2E: Pairing Flow Tests
    
    func testE2E_CompletePairingFlow() {
        // Step 1: Generate pairing code
        let pairingCode = pairingManager.generatePairingCode()
        XCTAssertEqual(pairingCode.count, 6)
        XCTAssertTrue(pairingCode.allSatisfy { $0.isNumber })
        
        // Step 2: Verify correct code
        let isValid = pairingManager.verifyPairingCode(pairingCode)
        XCTAssertTrue(isValid)
        
        // Step 3: Verify incorrect code fails
        let wrongCode = "000000"
        let isInvalid = pairingManager.verifyPairingCode(wrongCode)
        XCTAssertFalse(isInvalid)
    }
    
    func testE2E_PairingCodeLockout() {
        // Generate a code
        let _ = pairingManager.generatePairingCode()
        
        // Attempt 3 wrong codes
        for _ in 0..<3 {
            let _ = pairingManager.verifyPairingCode("000000")
        }
        
        // Verify lockout state
        XCTAssertTrue(pairingManager.isLockedOut)
        
        // Even correct code should fail during lockout
        let correctCode = pairingManager.currentPairingCode ?? ""
        let result = pairingManager.verifyPairingCode(correctCode)
        XCTAssertFalse(result)
    }
    
    // MARK: - E2E: BLE Communication Flow Tests
    
    func testE2E_ReceiveAndProcessCursorMoveCommand() {
        // Step 1: Simulate receiving cursor move command from iOS
        let commandData: [String: Any] = [
            "type": "cursorMove",
            "deltaX": 15.0,
            "deltaY": 25.0
        ]
        
        // Step 2: Process the command
        blePeripheralManager.simulateCommandReceived(commandData)
        
        // Step 3: Verify command was parsed and processed
        if let command = parseCommand(from: commandData) {
            commandProcessor.processCommand(command)
            
            // Step 4: Verify event generator received the cursor move
            XCTAssertEqual(eventGenerator.lastCursorDelta?.x, 15.0)
            XCTAssertEqual(eventGenerator.lastCursorDelta?.y, 25.0)
        } else {
            XCTFail("Failed to parse cursor move command")
        }
    }
    
    func testE2E_ReceiveAndProcessTapCommand() {
        // Step 1: Simulate receiving tap command from iOS
        let commandData: [String: Any] = [
            "type": "tap",
            "clickType": "single"
        ]
        
        // Step 2: Process the command
        blePeripheralManager.simulateCommandReceived(commandData)
        
        // Step 3: Verify command was processed
        if let command = parseCommand(from: commandData) {
            commandProcessor.processCommand(command)
            
            // Step 4: Verify click was generated
            XCTAssertEqual(eventGenerator.lastClickType, .single)
        } else {
            XCTFail("Failed to parse tap command")
        }
    }
    
    func testE2E_ReceiveAndProcessDoubleTapCommand() {
        // Step 1: Simulate receiving double tap command
        let commandData: [String: Any] = [
            "type": "tap",
            "clickType": "double"
        ]
        
        // Step 2: Process the command
        if let command = parseCommand(from: commandData) {
            commandProcessor.processCommand(command)
            
            // Step 3: Verify double click was generated
            XCTAssertEqual(eventGenerator.lastClickType, .double)
        } else {
            XCTFail("Failed to parse double tap command")
        }
    }
    
    func testE2E_SendStatusUpdate() {
        // Step 1: Create status data
        let statusData = StatusData(
            batteryLevel: 75,
            timestamp: Date(),
            connectionQuality: 90
        )
        
        // Step 2: Encode status data
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        if let jsonData = try? encoder.encode(statusData) {
            // Step 3: Simulate sending via BLE
            blePeripheralManager.simulateStatusSent(jsonData)
            
            // Step 4: Verify status was sent
            XCTAssertNotNil(blePeripheralManager.lastStatusData)
            XCTAssertEqual(blePeripheralManager.lastStatusData?.count, jsonData.count)
        } else {
            XCTFail("Failed to encode status data")
        }
    }
    
    // MARK: - E2E: Mode-Specific Operation Tests
    
    func testE2E_PresentationMode_NavigationButtons() {
        // Step 1: Set presentation mode
        commandProcessor.setMode(.presentation)
        
        // Step 2: Process back button command
        let backCommand: [String: Any] = [
            "type": "button",
            "action": "back"
        ]
        
        if let command = parseCommand(from: backCommand) {
            commandProcessor.processCommand(command)
            XCTAssertEqual(eventGenerator.lastNavigationKey, .leftArrow)
        }
        
        // Step 3: Process forward button command
        let forwardCommand: [String: Any] = [
            "type": "button",
            "action": "forward"
        ]
        
        if let command = parseCommand(from: forwardCommand) {
            commandProcessor.processCommand(command)
            XCTAssertEqual(eventGenerator.lastNavigationKey, .rightArrow)
        }
    }
    
    func testE2E_MediaControlMode_PlayPause() {
        // Step 1: Set media control mode
        commandProcessor.setMode(.mediaControl)
        
        // Step 2: Process play/pause command
        let playPauseCommand: [String: Any] = [
            "type": "mediaControl",
            "action": "playPause"
        ]
        
        if let command = parseCommand(from: playPauseCommand) {
            commandProcessor.processCommand(command)
            XCTAssertEqual(eventGenerator.lastMediaAction, .playPause)
        } else {
            XCTFail("Failed to parse play/pause command")
        }
    }
    
    func testE2E_MediaControlMode_VolumeControl() {
        // Step 1: Set media control mode
        commandProcessor.setMode(.mediaControl)
        
        // Step 2: Process volume up command
        let volumeUpCommand: [String: Any] = [
            "type": "mediaControl",
            "action": "volumeUp"
        ]
        
        if let command = parseCommand(from: volumeUpCommand) {
            commandProcessor.processCommand(command)
            XCTAssertEqual(eventGenerator.lastMediaAction, .volumeUp)
        }
        
        // Step 3: Process volume down command
        let volumeDownCommand: [String: Any] = [
            "type": "mediaControl",
            "action": "volumeDown"
        ]
        
        if let command = parseCommand(from: volumeDownCommand) {
            commandProcessor.processCommand(command)
            XCTAssertEqual(eventGenerator.lastMediaAction, .volumeDown)
        }
    }
    
    func testE2E_BasicMouseMode_ButtonActions() {
        // Step 1: Set basic mouse mode
        commandProcessor.setMode(.basicMouse)
        
        // Step 2: Process back button (Command+Left)
        let backCommand: [String: Any] = [
            "type": "button",
            "action": "back"
        ]
        
        if let command = parseCommand(from: backCommand) {
            commandProcessor.processCommand(command)
            XCTAssertEqual(eventGenerator.lastNavigationKey, .commandLeft)
        }
        
        // Step 3: Process forward button (Enter)
        let forwardCommand: [String: Any] = [
            "type": "button",
            "action": "forward"
        ]
        
        if let command = parseCommand(from: forwardCommand) {
            commandProcessor.processCommand(command)
            XCTAssertEqual(eventGenerator.lastNavigationKey, .enter)
        }
    }
    
    // MARK: - E2E: Mode Change Tests
    
    func testE2E_ModeChangeCommand() {
        // Test changing between all modes
        let modes: [ControlMode] = [.presentation, .mediaControl, .basicMouse]
        
        for mode in modes {
            let modeCommand: [String: Any] = [
                "type": "modeChange",
                "mode": mode.rawValue
            ]
            
            if let command = parseCommand(from: modeCommand) {
                commandProcessor.processCommand(command)
                XCTAssertEqual(commandProcessor.mode, mode)
            } else {
                XCTFail("Failed to parse mode change command for \(mode)")
            }
        }
    }
    
    // MARK: - E2E: Complete User Scenario Tests
    
    func testE2E_CompleteUserScenario_PresentationControl() {
        // Simulate a complete user scenario: controlling a presentation
        
        // Step 1: Pair devices
        let pairingCode = pairingManager.generatePairingCode()
        XCTAssertTrue(pairingManager.verifyPairingCode(pairingCode))
        
        // Step 2: Switch to presentation mode
        commandProcessor.setMode(.presentation)
        
        // Step 3: Move cursor to click on presentation
        let cursorMove = CursorMoveCommand(delta: CGPoint(x: 100, y: 50))
        commandProcessor.processCommand(cursorMove)
        XCTAssertNotNil(eventGenerator.lastCursorDelta)
        
        // Step 4: Click to start presentation
        let click = TapCommand(clickType: .single)
        commandProcessor.processCommand(click)
        XCTAssertEqual(eventGenerator.lastClickType, .single)
        
        // Step 5: Navigate slides with buttons
        let nextSlide = ButtonCommand(action: .forward)
        commandProcessor.processCommand(nextSlide)
        XCTAssertEqual(eventGenerator.lastNavigationKey, .rightArrow)
        
        let prevSlide = ButtonCommand(action: .back)
        commandProcessor.processCommand(prevSlide)
        XCTAssertEqual(eventGenerator.lastNavigationKey, .leftArrow)
    }
    
    func testE2E_CompleteUserScenario_MediaControl() {
        // Simulate a complete user scenario: controlling media playback
        
        // Step 1: Switch to media control mode
        commandProcessor.setMode(.mediaControl)
        
        // Step 2: Play/pause media
        let playPause = MediaControlCommand(action: .playPause)
        commandProcessor.processCommand(playPause)
        XCTAssertEqual(eventGenerator.lastMediaAction, .playPause)
        
        // Step 3: Adjust volume up
        let volumeUp = MediaControlCommand(action: .volumeUp)
        commandProcessor.processCommand(volumeUp)
        XCTAssertEqual(eventGenerator.lastMediaAction, .volumeUp)
        
        // Step 4: Adjust volume down
        let volumeDown = MediaControlCommand(action: .volumeDown)
        commandProcessor.processCommand(volumeDown)
        XCTAssertEqual(eventGenerator.lastMediaAction, .volumeDown)
    }
    
    // MARK: - Helper Methods
    
    private func parseCommand(from data: [String: Any]) -> Command? {
        guard let type = data["type"] as? String else { return nil }
        
        switch type {
        case "cursorMove":
            guard let deltaX = data["deltaX"] as? Double,
                  let deltaY = data["deltaY"] as? Double else { return nil }
            return CursorMoveCommand(delta: CGPoint(x: deltaX, y: deltaY))
            
        case "tap":
            guard let clickTypeStr = data["clickType"] as? String,
                  let clickType = ClickType(rawValue: clickTypeStr) else { return nil }
            return TapCommand(clickType: clickType)
            
        case "button":
            guard let actionStr = data["action"] as? String,
                  let action = ButtonAction(rawValue: actionStr) else { return nil }
            return ButtonCommand(action: action)
            
        case "mediaControl":
            guard let actionStr = data["action"] as? String,
                  let action = MediaAction(rawValue: actionStr) else { return nil }
            return MediaControlCommand(action: action)
            
        case "modeChange":
            guard let modeStr = data["mode"] as? String,
                  let mode = ControlMode(rawValue: modeStr) else { return nil }
            return ModeChangeCommand(mode: mode)
            
        default:
            return nil
        }
    }
}

// MARK: - Mock BLE Peripheral Manager

class MockBLEPeripheralManager {
    var lastStatusData: Data?
    var lastReceivedCommand: [String: Any]?
    var isAdvertising = false
    
    func simulateCommandReceived(_ command: [String: Any]) {
        lastReceivedCommand = command
    }
    
    func simulateStatusSent(_ data: Data) {
        lastStatusData = data
    }
    
    func startAdvertising() {
        isAdvertising = true
    }
    
    func stopAdvertising() {
        isAdvertising = false
    }
}
