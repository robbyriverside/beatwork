import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow, NSWindowDelegate {
  private var allowCloseAfterExitPrompt = false

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let defaultFrame = NSRect(
      origin: self.frame.origin,
      size: NSSize(width: 850, height: 700)
    )
    self.contentViewController = flutterViewController
    self.minSize = NSSize(width: 850, height: 700)
    self.setFrame(defaultFrame, display: true)
    self.setFrameAutosaveName("BeatWorkMainWindow")
    self.delegate = self

    RegisterGeneratedPlugins(registry: flutterViewController)
    DocumentOpenBridge.install(messenger: flutterViewController.engine.binaryMessenger)

    super.awakeFromNib()
    self.title = "BeatWork ScreenWriting"
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
