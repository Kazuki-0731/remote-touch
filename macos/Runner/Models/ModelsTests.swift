//
//  ModelsTests.swift
//  RemoteTouch macOS
//
//  Unit tests for data models
//

import Foundation

/// Test suite for data models
class ModelsTests {
    
    // MARK: - Command Tests
    
    static func testCursorMoveCommand() {
        print("Testing CursorMoveCommand...")
        
        let command = CursorMoveCommand(delta: CGPoint(x: 10.5, y: -20.3))
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(command)
            let jsonString = String(data: data, encoding: .utf8)!
            print("✓ CursorMoveCommand JSON: \(jsonString)")
            
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(CursorMoveCommand.self, from: data)
            assert(decoded.delta.dx == 10.5)
            assert(decoded.delta.dy == -20.3)
            print("✓ CursorMoveCommand encoding/decoding successful")
        } catch {
            print("✗ CursorMoveCommand test failed: \(error)")
        }
    }
    
    static func testTapCommand() {
        print("\nTesting TapCommand...")
        
        let command = TapCommand(clickType: .double)
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(command)
            let jsonString = String(data: data, encoding: .utf8)!
            print("✓ TapCommand JSON: \(jsonString)")
            
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(TapCommand.self, from: data)
            assert(decoded.clickType == .double)
            print("✓ TapCommand encoding/decoding successful")
        } catch {
            print("✗ TapCommand test failed: \(error)")
        }
    }
    
    static func testButtonCommand() {
        print("\nTesting ButtonCommand...")
        
        let command = ButtonCommand(action: .back)
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(command)
            let jsonString = String(data: data, encoding: .utf8)!
            print("✓ ButtonCommand JSON: \(jsonString)")
            
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(ButtonCommand.self, from: data)
            assert(decoded.action == .back)
            print("✓ ButtonCommand encoding/decoding successful")
        } catch {
            print("✗ ButtonCommand test failed: \(error)")
        }
    }
    
    static func testModeChangeCommand() {
        print("\nTesting ModeChangeCommand...")
        
        let command = ModeChangeCommand(mode: .presentation)
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(command)
            let jsonString = String(data: data, encoding: .utf8)!
            print("✓ ModeChangeCommand JSON: \(jsonString)")
            
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(ModeChangeCommand.self, from: data)
            assert(decoded.mode == .presentation)
            print("✓ ModeChangeCommand encoding/decoding successful")
        } catch {
            print("✗ ModeChangeCommand test failed: \(error)")
        }
    }
    
    static func testMediaControlCommand() {
        print("\nTesting MediaControlCommand...")
        
        let command = MediaControlCommand(action: .playPause)
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(command)
            let jsonString = String(data: data, encoding: .utf8)!
            print("✓ MediaControlCommand JSON: \(jsonString)")
            
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(MediaControlCommand.self, from: data)
            assert(decoded.action == .playPause)
            print("✓ MediaControlCommand encoding/decoding successful")
        } catch {
            print("✗ MediaControlCommand test failed: \(error)")
        }
    }
    
    // MARK: - StatusData Tests
    
    static func testStatusData() {
        print("\nTesting StatusData...")
        
        let status = StatusData(batteryLevel: 85, connectionQuality: 95)
        
        do {
            let data = try status.toJSON()
            let jsonString = String(data: data, encoding: .utf8)!
            print("✓ StatusData JSON: \(jsonString)")
            
            let decoded = try StatusData.fromJSON(data)
            assert(decoded.batteryLevel == 85)
            assert(decoded.connectionQuality == 95)
            print("✓ StatusData encoding/decoding successful")
            print("✓ StatusData description: \(decoded)")
        } catch {
            print("✗ StatusData test failed: \(error)")
        }
    }
    
    // MARK: - Device Tests
    
    static func testDevice() {
        print("\nTesting Device...")
        
        let device = Device(
            id: "test-id-123",
            name: "Test Mac",
            peripheralUUID: "uuid-456",
            lastConnected: Date(),
            isPaired: true
        )
        
        do {
            let data = try device.toJSON()
            let jsonString = String(data: data, encoding: .utf8)!
            print("✓ Device JSON: \(jsonString)")
            
            let decoded = try Device.fromJSON(data)
            assert(decoded.id == "test-id-123")
            assert(decoded.name == "Test Mac")
            assert(decoded.isPaired == true)
            print("✓ Device encoding/decoding successful")
            print("✓ Device description: \(decoded)")
            
            // Test copyWith
            let updated = device.copyWith(name: "Updated Mac")
            assert(updated.name == "Updated Mac")
            assert(updated.id == device.id)
            print("✓ Device copyWith successful")
        } catch {
            print("✗ Device test failed: \(error)")
        }
    }
    
    // MARK: - AppSettings Tests
    
    static func testAppSettings() {
        print("\nTesting AppSettings...")
        
        let settings = AppSettings(
            sensitivity: 1.5,
            idleTimeout: 120.0,
            autoReconnect: true,
            maxReconnectAttempts: 5
        )
        
        do {
            let data = try settings.toJSON()
            let jsonString = String(data: data, encoding: .utf8)!
            print("✓ AppSettings JSON: \(jsonString)")
            
            let decoded = try AppSettings.fromJSON(data)
            assert(decoded.sensitivity == 1.5)
            assert(decoded.idleTimeout == 120.0)
            assert(decoded.autoReconnect == true)
            assert(decoded.maxReconnectAttempts == 5)
            print("✓ AppSettings encoding/decoding successful")
            print("✓ AppSettings description: \(decoded)")
            
            // Test copyWith
            let updated = settings.copyWith(sensitivity: 2.0)
            assert(updated.sensitivity == 2.0)
            assert(updated.idleTimeout == settings.idleTimeout)
            print("✓ AppSettings copyWith successful")
        } catch {
            print("✗ AppSettings test failed: \(error)")
        }
    }
    
    // MARK: - Run All Tests
    
    static func runAllTests() {
        print("=== Running Data Models Tests ===\n")
        
        testCursorMoveCommand()
        testTapCommand()
        testButtonCommand()
        testModeChangeCommand()
        testMediaControlCommand()
        testStatusData()
        testDevice()
        testAppSettings()
        
        print("\n=== All Tests Completed ===")
    }
}
