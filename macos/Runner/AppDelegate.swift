import Cocoa
import FlutterMacOS

enum DocumentOpenBridge {
  private static var channel: FlutterMethodChannel?
  private static var accessChannel: FlutterMethodChannel?
  private static let bookmarkKey = "documentSecurityBookmarks"
  private static var activeAccess: [String: URL] = [:]
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
    let documentAccessChannel = FlutterMethodChannel(
      name: "beatwork/document_access",
      binaryMessenger: messenger
    )
    accessChannel = documentAccessChannel
    documentAccessChannel.setMethodCallHandler { call, result in
      guard let path = call.arguments as? String, !path.isEmpty else {
        result(FlutterError(
          code: "invalid_path",
          message: "A document path is required.",
          details: nil
        ))
        return
      }
      do {
        switch call.method {
        case "restore":
          result(try restoreAccess(path: path))
        case "remember":
          try rememberAccess(path: path)
          result(nil)
        default:
          result(FlutterMethodNotImplemented)
        }
      } catch {
        result(FlutterError(
          code: "document_access_error",
          message: error.localizedDescription,
          details: nil
        ))
      }
    }
  }

  private static func rememberAccess(path: String) throws {
    let url = URL(fileURLWithPath: path).standardizedFileURL
    let bookmark = try url.bookmarkData(
      options: .withSecurityScope,
      includingResourceValuesForKeys: nil,
      relativeTo: nil
    )
    var bookmarks = UserDefaults.standard.dictionary(forKey: bookmarkKey) ?? [:]
    bookmarks[url.path] = bookmark
    UserDefaults.standard.set(bookmarks, forKey: bookmarkKey)
  }

  private static func restoreAccess(path: String) throws -> Bool {
    let requested = URL(fileURLWithPath: path).standardizedFileURL.path
    if activeAccess[requested] != nil { return true }
    let bookmarks = UserDefaults.standard.dictionary(forKey: bookmarkKey) ?? [:]
    guard let value = bookmarks[requested] else {
      return false
    }
    guard let bookmark = value as? Data else {
      throw NSError(domain: "BeatWorkDocumentAccess", code: 3, userInfo: [
        NSLocalizedDescriptionKey: "The project's saved access is invalid. Select it again using Open."
      ])
    }
    var stale = false
    let url = try URL(
      resolvingBookmarkData: bookmark,
      options: .withSecurityScope,
      relativeTo: nil,
      bookmarkDataIsStale: &stale
    )
    guard url.standardizedFileURL.path == requested else {
      throw NSError(domain: "BeatWorkDocumentAccess", code: 1, userInfo: [
        NSLocalizedDescriptionKey: "The project has moved. Select it again using Open."
      ])
    }
    guard url.startAccessingSecurityScopedResource() else {
      throw NSError(domain: "BeatWorkDocumentAccess", code: 2, userInfo: [
        NSLocalizedDescriptionKey: "Access to the project has expired. Select it again using Open."
      ])
    }
    do {
      if stale { try rememberAccess(path: requested) }
      activeAccess[requested] = url
      return true
    } catch {
      url.stopAccessingSecurityScopedResource()
      throw error
    }
  }

  static func stopAccessingDocuments() {
    for url in activeAccess.values { url.stopAccessingSecurityScopedResource() }
    activeAccess.removeAll()
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

  override func applicationWillTerminate(_ notification: Notification) {
    DocumentOpenBridge.stopAccessingDocuments()
    super.applicationWillTerminate(notification)
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
