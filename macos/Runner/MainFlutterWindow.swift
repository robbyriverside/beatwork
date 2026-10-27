import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow, NSWindowDelegate {
  private var allowCloseAfterExitPrompt = false

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    self.delegate = self

    RegisterGeneratedPlugins(registry: flutterViewController)
    DocumentOpenBridge.install(messenger: flutterViewController.engine.binaryMessenger)

    super.awakeFromNib()
  }

  func windowShouldClose(_ sender: NSWindow) -> Bool {
    guard !allowCloseAfterExitPrompt else { return true }
    (NSApp.delegate as? AppDelegate)?.requestExit { [weak self] in
      guard let self else { return }
      self.allowCloseAfterExitPrompt = true
      self.close()
    }
    return false
  }
}
