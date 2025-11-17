import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()

    // Initialize ApplicationController for menu bar app
    NSLog("MainFlutterWindow: awakeFromNib called, initializing ApplicationController")
    let _ = ApplicationController.shared
    ApplicationController.shared.start()
    NSLog("MainFlutterWindow: ApplicationController initialized and started")

    // Hide the main window since this is a menu bar only app
    self.orderOut(nil)
  }
}
