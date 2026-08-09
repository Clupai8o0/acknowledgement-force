import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  var strictMode: StrictMode?

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    strictMode = StrictMode(window: self, messenger: flutterViewController.engine.binaryMessenger)

    super.awakeFromNib()
  }
}
