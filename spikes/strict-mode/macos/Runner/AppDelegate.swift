import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  /// Q3b — how far can an app go in refusing Cmd-Q?
  override func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
    if AppDelegateBridge.refuseQuit { return .terminateCancel }
    return .terminateNow
  }
}
