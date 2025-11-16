import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  
  private let applicationController = ApplicationController.shared
  
  override func applicationDidFinishLaunching(_ notification: Notification) {
    super.applicationDidFinishLaunching(notification)
    
    // Start the RemoteTouch application controller
    applicationController.start()
  }
  
  override func applicationWillTerminate(_ notification: Notification) {
    super.applicationWillTerminate(notification)
    
    // Stop the application controller
    applicationController.stop()
  }
  
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    // Don't quit when Flutter window closes - we're a menu bar app
    return false
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
