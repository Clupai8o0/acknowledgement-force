import Foundation
import AppKit

// Ensures only one Force process runs at a time. launchd can relaunch Force on
// a schedule (or on login) while a copy is already up; without this guard each
// relaunch stacks another window. The second process hands focus to the first
// and exits immediately.
enum SingleInstance {
    static let activateNotification = Notification.Name("com.acknowledgementforce.activate")

    nonisolated(unsafe) private static var lockFD: Int32 = -1

    private static var lockURL: URL? {
        let fm = FileManager.default
        guard let dir = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("Force", isDirectory: true) else { return nil }
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent(".instance.lock")
    }

    /// Returns true if this process owns the single-instance lock. When false,
    /// another Force is already running — caller should ask it to come forward
    /// and then terminate.
    static func acquire() -> Bool {
        guard let path = lockURL?.path else { return true }
        let fd = open(path, O_CREAT | O_RDWR, 0o644)
        guard fd >= 0 else { return true }
        if flock(fd, LOCK_EX | LOCK_NB) != 0 {
            close(fd)
            return false
        }
        lockFD = fd  // held for the lifetime of the process
        return true
    }

    /// Tell the running instance to surface its window, then quit this copy.
    static func handoffAndExit() -> Never {
        DistributedNotificationCenter.default()
            .postNotificationName(activateNotification, object: nil, deliverImmediately: true)
        exit(0)
    }

    /// Listen for handoff requests from later launches and pull our window up.
    static func listenForActivation() {
        DistributedNotificationCenter.default().addObserver(
            forName: activateNotification, object: nil, queue: .main
        ) { _ in
            MainActor.assumeIsolated {
                NSApp.activate(ignoringOtherApps: true)
                for window in NSApp.windows where window.canBecomeMain {
                    window.makeKeyAndOrderFront(nil)
                }
            }
        }
    }
}
