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

  static func requestExit(completion: @escaping (Bool) -> Void) {
    guard isReady, let channel else {
      completion(false)
      return
    }
    channel.invokeMethod("requestExit", arguments: nil) { result in
      completion((result as? Bool) ?? false)
    }
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
  private var exitPromptPending = false
  private var terminationApproved = false

  @IBAction func showEventPool(_ sender: Any?) {
    DocumentOpenBridge.showEventPool()
  }

  func requestExit(onApproval: @escaping () -> Void) {
    guard !exitPromptPending else { return }
    exitPromptPending = true
    DocumentOpenBridge.requestExit { [weak self] shouldExit in
      guard let self else { return }
      self.exitPromptPending = false
      guard shouldExit else { return }
      self.terminationApproved = true
      onApproval()
    }
  }

  override func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
    if terminationApproved {
      terminationApproved = false
      return .terminateNow
    }
    requestExit {
      sender.terminate(nil)
    }
    return .terminateCancel
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
