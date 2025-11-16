//
//  CommandProcessorTests.swift
//  RemoteTouch macOS Tests
//
//  Tests for CommandProcessor
//

import XCTest
import CoreGraphics
@testable import Runner

class CommandProcessorTests: XCTestCase {
    
    var commandProcessor: CommandProcessor!
    var mockEventGenerator: MockEventGenerator!
    
    override func setUp() {
        super.setUp()
        mockEventGenerator = MockEventGenerator()
        commandProcessor = CommandProcessor(eventGenerator: mockEventGenerator)
    }
    
    override func tearDown() {
        commandProcessor = nil
        mockEventGenerator = nil
        super.tearDown()
    }
    
    // MARK: - Mode Change Tests
    
    func testModeChangeCommand() {
        // Test changing to presentation mode
        let presentationCommand = ModeChangeCommand(mode: .presentation)
        commandProcessor.processCommand(presentationCommand)
        XCTAssertEqual(commandProcessor.mode, .presentation)
        
        // Test changing to media control mode
        let mediaCommand = ModeChangeCommand(mode: .mediaControl)
        commandProcessor.processCommand(mediaCommand)
        XCTAssertEqual(commandProcessor.mode, .mediaControl)
        
        // Test changing to basic mouse mode
        let basicCommand = ModeChangeCommand(mode: .basicMouse)
        commandProcessor.processCommand(basicCommand)
        XCTAssertEqual(commandProcessor.mode, .basicMouse)
    }
    
    // MARK: - Cursor Movement Tests
    
    func testCursorMoveCommand() {
        let delta = CGPoint(x: 10, y: 20)
        let command = CursorMoveCommand(delta: delta)
        
        commandProcessor.processCommand(command)
        
        XCTAssertEqual(mockEventGenerator.lastCursorDelta?.x, 10)
        XCTAssertEqual(mockEventGenerator.lastCursorDelta?.y, 20)
    }
    
    // MARK: - Tap Tests
    
    func testSingleTapCommand() {
        let command = TapCommand(clickType: .single)
        
        commandProcessor.processCommand(command)
        
        XCTAssertEqual(mockEventGenerator.lastClickType, .single)
    }
    
    func testDoubleTapCommand() {
        let command = TapCommand(clickType: .double)
        
        commandProcessor.processCommand(command)
        
        XCTAssertEqual(mockEventGenerator.lastClickType, .double)
    }
    
    func testTapInMediaControlMode() {
        // Set to media control mode
        commandProcessor.setMode(.mediaControl)
        
        // Single tap should trigger play/pause
        let command = TapCommand(clickType: .single)
        commandProcessor.processCommand(command)
        
        XCTAssertEqual(mockEventGenerator.lastMediaAction, .playPause)
    }
    
    // MARK: - Button Action Tests - Presentation Mode
    
    func testBackButtonInPresentationMode() {
        commandProcessor.setMode(.presentation)
        
        let command = ButtonCommand(action: .back)
        commandProcessor.processCommand(command)
        
        XCTAssertEqual(mockEventGenerator.lastNavigationKey, .leftArrow)
    }
    
    func testForwardButtonInPresentationMode() {
        commandProcessor.setMode(.presentation)
        
        let command = ButtonCommand(action: .forward)
        commandProcessor.processCommand(command)
        
        XCTAssertEqual(mockEventGenerator.lastNavigationKey, .rightArrow)
    }
    
    // MARK: - Button Action Tests - Basic Mouse Mode
    
    func testBackButtonInBasicMouseMode() {
        commandProcessor.setMode(.basicMouse)
        
        let command = ButtonCommand(action: .back)
        commandProcessor.processCommand(command)
        
        XCTAssertEqual(mockEventGenerator.lastNavigationKey, .commandLeft)
    }
    
    func testForwardButtonInBasicMouseMode() {
        commandProcessor.setMode(.basicMouse)
        
        let command = ButtonCommand(action: .forward)
        commandProcessor.processCommand(command)
        
        XCTAssertEqual(mockEventGenerator.lastNavigationKey, .enter)
    }
    
    // MARK: - Button Action Tests - Media Control Mode
    
    func testBackButtonInMediaControlMode() {
        commandProcessor.setMode(.mediaControl)
        
        let command = ButtonCommand(action: .back)
        commandProcessor.processCommand(command)
        
        XCTAssertEqual(mockEventGenerator.lastNavigationKey, .leftArrow)
    }
    
    func testForwardButtonInMediaControlMode() {
        commandProcessor.setMode(.mediaControl)
        
        let command = ButtonCommand(action: .forward)
        commandProcessor.processCommand(command)
        
        XCTAssertEqual(mockEventGenerator.lastNavigationKey, .rightArrow)
    }
    
    // MARK: - Media Control Tests
    
    func testMediaControlPlayPause() {
        let command = MediaControlCommand(action: .playPause)
        
        commandProcessor.processCommand(command)
        
        XCTAssertEqual(mockEventGenerator.lastMediaAction, .playPause)
    }
    
    func testMediaControlVolumeUp() {
        let command = MediaControlCommand(action: .volumeUp)
        
        commandProcessor.processCommand(command)
        
        XCTAssertEqual(mockEventGenerator.lastMediaAction, .volumeUp)
    }
    
    func testMediaControlVolumeDown() {
        let command = MediaControlCommand(action: .volumeDown)
        
        commandProcessor.processCommand(command)
        
        XCTAssertEqual(mockEventGenerator.lastMediaAction, .volumeDown)
    }
}

// MARK: - Mock Event Generator

class MockEventGenerator: EventGenerator {
    
    var lastCursorDelta: CGPoint?
    var lastClickType: ClickType?
    var lastNavigationKey: NavigationKey?
    var lastMediaAction: MediaAction?
    
    override func moveCursor(by delta: CGPoint) {
        lastCursorDelta = delta
    }
    
    override func generateClick(type: ClickType) {
        lastClickType = type
    }
    
    override func generateNavigationKey(_ key: NavigationKey) {
        lastNavigationKey = key
    }
    
    override func generateMediaControl(_ action: MediaAction) {
        lastMediaAction = action
    }
}
