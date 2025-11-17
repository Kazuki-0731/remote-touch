import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {

    private var applicationController: ApplicationController?

    override func applicationDidFinishLaunching(_ notification: Notification) {
        super.applicationDidFinishLaunching(notification)

        NSLog("AppDelegate: applicationDidFinishLaunching called")

        // Initialize ApplicationController after super.applicationDidFinishLaunching
        applicationController = ApplicationController.shared
        NSLog("AppDelegate: ApplicationController initialized")

        applicationController?.start()
        NSLog("AppDelegate: ApplicationController.start() called")
    }

    override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Don't quit when window is closed - we're a menu bar app
        return false
    }

    override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}
