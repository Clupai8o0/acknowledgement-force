// Posts the same distributed notification names NSWorkspace re-broadcasts, so the
// Swift->Dart delivery path for wake events can be exercised without sudo
// (scheduling a real system wake needs `sudo pmset schedule wake`).
import Foundation
let name = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "NSWorkspaceDidWakeNotification"
DistributedNotificationCenter.default().postNotificationName(
  NSNotification.Name(name), object: nil, userInfo: nil, deliverImmediately: true)
print("posted \(name)")
