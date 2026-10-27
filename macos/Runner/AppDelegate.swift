import Cocoa
import FlutterMacOS

enum DocumentOpenBridge {
  private static var channel: FlutterMethodChannel?
  private static var pendingPaths: [String] = []
  private static var isReady = false

  static func install(messenger: FlutterBinaryMessenger) {
    let methodChannel = FlutterMethodChannel(
      name: "beatwork/documents",
      binaryMessenger: messenger
    )
    channel = methodChannel
    methodChannel.setMethodCallHandler { call, result in
      guard call.method == "ready" else {
        result(FlutterMethodNotImplemented)
        return
      }
      isReady = true
      flush()
      result(nil)
    }
  }

  static func open(paths: [String]) {
    pendingPaths.append(contentsOf: paths)
    flush()
  }

  static func showEventPool() {
    channel?.invokeMethod("showEventPool", arguments: nil)
  }

  private static func flush() {
    guard isReady, let channel else { return }
    let paths = pendingPaths
    pendingPaths.removeAll()
    for path in paths {
      channel.invokeMethod("openDocument", arguments: path)
    }
  }
}

@main
class AppDelegate: FlutterAppDelegate {
  @IBAction func showEventPool(_ sender: Any?) {
    DocumentOpenBridge.showEventPool()
  }

  override func application(_ sender: NSApplication, openFiles filenames: [String]) {
    DocumentOpenBridge.open(paths: filenames)
    sender.reply(toOpenOrPrint: .success)
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
