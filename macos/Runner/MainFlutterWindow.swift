import AVFoundation
import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    if AVCaptureDevice.authorizationStatus(for: .audio) == .notDetermined {
      AVCaptureDevice.requestAccess(for: .audio) { _ in }
    }

    super.awakeFromNib()
  }
}
