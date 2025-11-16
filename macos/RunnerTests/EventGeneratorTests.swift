//
//  EventGeneratorTests.swift
//  RunnerTests
//
//  Tests for EventGenerator functionality
//

import XCTest
@testable import Runner

class EventGeneratorTests: XCTestCase {
    
    var eventGenerator: EventGenerator!
    
    override func setUp() {
        super.setUp()
        eventGenerator = EventGenerator.shared
    }
    
    override func tearDown() {
        eventGenerator = nil
        super.tearDown()
    }
    
    // MARK: - Navigation Key Tests
    
    func testNavigationKeyDefinitions() {
        // Test that navigation keys have correct key codes
        XCTAssertEqual(NavigationKey.leftArrow.keyCode, 0x7B)
        XCTAssertEqual(NavigationKey.rightArrow.keyCode, 0x7C)
        XCTAssertEqual(NavigationKey.upArrow.keyCode, 0x7E)
        XCTAssertEqual(NavigationKey.downArrow.keyCode, 0x7D)
        XCTAssertEqual(NavigationKey.enter.keyCode, 0x24)
        XCTAssertEqual(NavigationKey.escape.keyCode, 0x35)
        XCTAssertEqual(NavigationKey.space.keyCode, 0x31)
    }
    
    func testNavigationKeyModifiers() {
        // Test that command keys have correct modifiers
        XCTAssertTrue(NavigationKey.commandLeft.modifiers.contains(.maskCommand))
        XCTAssertTrue(NavigationKey.commandRight.modifiers.contains(.maskCommand))
        
        // Test that regular keys have no modifiers
        XCTAssertTrue(NavigationKey.leftArrow.modifiers.isEmpty)
        XCTAssertTrue(NavigationKey.enter.modifiers.isEmpty)
    }
    
    // MARK: - Event Generation Tests
    // Note: These tests verify the methods can be called without crashing
    // Actual event generation requires accessibility permissions
    
    func testMoveCursorDoesNotCrash() {
        // This should not crash even without accessibility permission
        let delta = CGPoint(x: 10, y: 10)
        eventGenerator.moveCursor(by: delta)
        
        // If we get here, the method didn't crash
        XCTAssertTrue(true)
    }
    
    func testGenerateClickDoesNotCrash() {
        // This should not crash even without accessibility permission
        eventGenerator.generateClick(type: .single)
        eventGenerator.generateClick(type: .double)
        
        // If we get here, the methods didn't crash
        XCTAssertTrue(true)
    }
    
    func testGenerateKeyPressDoesNotCrash() {
        // This should not crash even without accessibility permission
        eventGenerator.generateKeyPress(0x7B) // Left arrow
        eventGenerator.generateKeyPress(0x24) // Enter
        
        // If we get here, the methods didn't crash
        XCTAssertTrue(true)
    }
    
    func testGenerateNavigationKeyDoesNotCrash() {
        // This should not crash even without accessibility permission
        eventGenerator.generateNavigationKey(.leftArrow)
        eventGenerator.generateNavigationKey(.enter)
        eventGenerator.generateNavigationKey(.commandLeft)
        
        // If we get here, the methods didn't crash
        XCTAssertTrue(true)
    }
    
    func testGenerateMediaControlDoesNotCrash() {
        // This should not crash even without accessibility permission
        eventGenerator.generateMediaControl(.playPause)
        eventGenerator.generateMediaControl(.volumeUp)
        eventGenerator.generateMediaControl(.volumeDown)
        
        // If we get here, the methods didn't crash
        XCTAssertTrue(true)
    }
}
