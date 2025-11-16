//
//  PairingManager.swift
//  RemoteTouch macOS
//
//  Manages device pairing with 6-digit code verification
//

import Foundation
import CoreBluetooth

/// Delegate protocol for pairing events
protocol PairingManagerDelegate: AnyObject {
    func pairingManager(_ manager: PairingManager, didGenerateCode code: String)
    func pairingManager(_ manager: PairingManager, didCompletePairingWith device: Device)
    func pairingManager(_ manager: PairingManager, didFailPairingWithError error: PairingError)
    func pairingManager(_ manager: PairingManager, didLockoutUntil date: Date)
}

/// Errors that can occur during pairing
enum PairingError: Error {
    case invalidCode
    case lockedOut
    case tooManyAttempts
    case storageError
    case alreadyPaired
    
    var localizedDescription: String {
        switch self {
        case .invalidCode:
            return "Invalid pairing code"
        case .lockedOut:
            return "Too many failed attempts. Please try again later."
        case .tooManyAttempts:
            return "Maximum pairing attempts exceeded"
        case .storageError:
            return "Failed to save device information"
        case .alreadyPaired:
            return "Device is already paired"
        }
    }
}

/// Manages pairing functionality including code generation, verification, and device storage
class PairingManager {
    
    // MARK: - Properties
    
    weak var delegate: PairingManagerDelegate?
    
    private var currentPairingCode: String?
    private var pairingCodeGeneratedAt: Date?
    private var failedAttempts: Int = 0
    private var lockoutUntil: Date?
    private var pendingCentral: CBCentral?
    
    private let userDefaults = UserDefaults.standard
    private let maxFailedAttempts = 3
    private let lockoutDuration: TimeInterval = 5 * 60 // 5 minutes
    private let codeTimeout: TimeInterval = 60 // 60 seconds
    
    // UserDefaults keys
    private let pairedDevicesKey = "pairedDevices"
    private let lockoutDateKey = "pairingLockoutDate"
    
    // MARK: - Public Methods
    
    /// Generate a new 6-digit pairing code
    func generatePairingCode(for central: CBCentral) -> String {
        // Check if locked out
        if let lockoutDate = lockoutUntil, Date() < lockoutDate {
            return ""
        }
        
        // Generate random 6-digit code
        let code = String(format: "%06d", Int.random(in: 0...999999))
        
        currentPairingCode = code
        pairingCodeGeneratedAt = Date()
        pendingCentral = central
        failedAttempts = 0
        
        print("PairingManager: Generated pairing code: \(code)")
        delegate?.pairingManager(self, didGenerateCode: code)
        
        return code
    }
    
    /// Verify a pairing code submitted by the iOS device
    func verifyPairingCode(_ code: String, from central: CBCentral, deviceName: String) -> Bool {
        // Check if locked out
        if let lockoutDate = lockoutUntil, Date() < lockoutDate {
            print("PairingManager: Pairing locked out until \(lockoutDate)")
            delegate?.pairingManager(self, didFailPairingWithError: .lockedOut)
            return false
        }
        
        // Check if code exists
        guard let expectedCode = currentPairingCode else {
            print("PairingManager: No pairing code generated")
            delegate?.pairingManager(self, didFailPairingWithError: .invalidCode)
            return false
        }
        
        // Check if code has expired (60 seconds timeout)
        if let generatedAt = pairingCodeGeneratedAt,
           Date().timeIntervalSince(generatedAt) > codeTimeout {
            print("PairingManager: Pairing code expired")
            currentPairingCode = nil
            pairingCodeGeneratedAt = nil
            delegate?.pairingManager(self, didFailPairingWithError: .invalidCode)
            return false
        }
        
        // Check if central matches
        guard central.identifier == pendingCentral?.identifier else {
            print("PairingManager: Central mismatch")
            delegate?.pairingManager(self, didFailPairingWithError: .invalidCode)
            return false
        }
        
        // Verify code
        if code == expectedCode {
            print("PairingManager: Pairing code verified successfully")
            
            // Create device and save
            let device = Device(
                id: central.identifier.uuidString,
                name: deviceName,
                peripheralUUID: central.identifier.uuidString,
                lastConnected: Date(),
                isPaired: true
            )
            
            do {
                try savePairedDevice(device)
                
                // Clear pairing state
                currentPairingCode = nil
                pairingCodeGeneratedAt = nil
                pendingCentral = nil
                failedAttempts = 0
                
                delegate?.pairingManager(self, didCompletePairingWith: device)
                return true
            } catch {
                print("PairingManager: Failed to save device - \(error)")
                delegate?.pairingManager(self, didFailPairingWithError: .storageError)
                return false
            }
        } else {
            // Incorrect code
            failedAttempts += 1
            print("PairingManager: Invalid code. Attempt \(failedAttempts)/\(maxFailedAttempts)")
            
            if failedAttempts >= maxFailedAttempts {
                // Lock out for 5 minutes
                let lockoutDate = Date().addingTimeInterval(lockoutDuration)
                lockoutUntil = lockoutDate
                userDefaults.set(lockoutDate, forKey: lockoutDateKey)
                
                print("PairingManager: Too many failed attempts. Locked out until \(lockoutDate)")
                
                // Clear pairing state
                currentPairingCode = nil
                pairingCodeGeneratedAt = nil
                pendingCentral = nil
                
                delegate?.pairingManager(self, didLockoutUntil: lockoutDate)
                delegate?.pairingManager(self, didFailPairingWithError: .tooManyAttempts)
            } else {
                delegate?.pairingManager(self, didFailPairingWithError: .invalidCode)
            }
            
            return false
        }
    }
    
    /// Check if a device is already paired
    func isDevicePaired(_ centralIdentifier: UUID) -> Bool {
        let devices = loadPairedDevices()
        return devices.contains { $0.peripheralUUID == centralIdentifier.uuidString }
    }
    
    /// Get current pairing code (for display purposes)
    func getCurrentPairingCode() -> String? {
        // Check if code has expired
        if let generatedAt = pairingCodeGeneratedAt,
           Date().timeIntervalSince(generatedAt) > codeTimeout {
            currentPairingCode = nil
            pairingCodeGeneratedAt = nil
            return nil
        }
        
        return currentPairingCode
    }
    
    /// Check if currently locked out
    func isLockedOut() -> Bool {
        if let lockoutDate = lockoutUntil {
            if Date() < lockoutDate {
                return true
            } else {
                // Lockout expired
                lockoutUntil = nil
                userDefaults.removeObject(forKey: lockoutDateKey)
                return false
            }
        }
        return false
    }
    
    /// Get remaining lockout time in seconds
    func getRemainingLockoutTime() -> TimeInterval? {
        guard let lockoutDate = lockoutUntil else {
            return nil
        }
        
        let remaining = lockoutDate.timeIntervalSince(Date())
        return remaining > 0 ? remaining : nil
    }
    
    /// Cancel current pairing attempt
    func cancelPairing() {
        currentPairingCode = nil
        pairingCodeGeneratedAt = nil
        pendingCentral = nil
        failedAttempts = 0
        print("PairingManager: Pairing cancelled")
    }
    
    // MARK: - Device Storage
    
    /// Save a paired device to persistent storage
    private func savePairedDevice(_ device: Device) throws {
        var devices = loadPairedDevices()
        
        // Check if device already exists
        if let index = devices.firstIndex(where: { $0.id == device.id }) {
            // Update existing device
            devices[index] = device
        } else {
            // Add new device
            devices.append(device)
        }
        
        // Encode and save
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(devices)
        userDefaults.set(data, forKey: pairedDevicesKey)
        
        print("PairingManager: Saved device: \(device.name)")
    }
    
    /// Load all paired devices from persistent storage
    func loadPairedDevices() -> [Device] {
        guard let data = userDefaults.data(forKey: pairedDevicesKey) else {
            return []
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let devices = try decoder.decode([Device].self, from: data)
            return devices
        } catch {
            print("PairingManager: Failed to load devices - \(error)")
            return []
        }
    }
    
    /// Remove a paired device
    func removePairedDevice(_ deviceId: String) throws {
        var devices = loadPairedDevices()
        devices.removeAll { $0.id == deviceId }
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(devices)
        userDefaults.set(data, forKey: pairedDevicesKey)
        
        print("PairingManager: Removed device: \(deviceId)")
    }
    
    /// Update last connected time for a device
    func updateDeviceLastConnected(_ deviceId: String) throws {
        var devices = loadPairedDevices()
        
        guard let index = devices.firstIndex(where: { $0.id == deviceId }) else {
            return
        }
        
        devices[index] = devices[index].copyWith(lastConnected: Date())
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(devices)
        userDefaults.set(data, forKey: pairedDevicesKey)
        
        print("PairingManager: Updated last connected for device: \(deviceId)")
    }
    
    // MARK: - Initialization
    
    init() {
        // Load lockout state if exists
        if let lockoutDate = userDefaults.object(forKey: lockoutDateKey) as? Date {
            if Date() < lockoutDate {
                lockoutUntil = lockoutDate
                print("PairingManager: Loaded lockout state until \(lockoutDate)")
            } else {
                // Lockout expired, clear it
                userDefaults.removeObject(forKey: lockoutDateKey)
            }
        }
    }
}
