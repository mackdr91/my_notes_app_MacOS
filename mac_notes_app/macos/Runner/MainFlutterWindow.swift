/*
 * Author: Domonick Mack
 * Date: 2026-11-10
 * Description: Custom borderless transparent macOS window configuration for Lusid.
 */

import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController

    // Configure authentic Lusid macOS styling
    self.titleVisibility = .hidden
    self.titlebarAppearsTransparent = true
    self.styleMask.insert(.fullSizeContentView)
    self.isMovableByWindowBackground = false

    // Set initial size and min size for Lusid desktop app
    var frame = self.frame
    frame.size = NSMakeSize(1100, 720)
    self.minSize = NSMakeSize(780, 480)
    self.setFrame(frame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
