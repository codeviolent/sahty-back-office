import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let minimumWindowSize = NSSize(width: 1280, height: 800)
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.minSize = minimumWindowSize
    self.contentMinSize = minimumWindowSize
    self.contentViewController = flutterViewController
    self.setFrame(
      NSRect(
        x: windowFrame.origin.x,
        y: windowFrame.origin.y,
        width: max(windowFrame.width, minimumWindowSize.width),
        height: max(windowFrame.height, minimumWindowSize.height)
      ),
      display: true
    )

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
