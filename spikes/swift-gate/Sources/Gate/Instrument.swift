import Foundation
import QuartzCore
import AppKit

/// Cold-start instrumentation for the spike measurements.
///
/// t0 is the kernel's record of when this process was `exec`d (`kp_proc.p_starttime`),
/// so dyld, the Swift runtime and AppKit bring-up are all inside the number —
/// not just the time from the first line of Swift.
///
/// t1 is the completion of the first CoreAnimation transaction after the root
/// view's `onAppear`, i.e. the first frame handed to the window server.
///
/// Enable with GATE_MEASURE=1. GATE_MEASURE=exit also quits after reporting,
/// so a shell loop can take 5 cold runs.
@MainActor
enum Instrument {
    private static let mode = ProcessInfo.processInfo.environment["GATE_MEASURE"]
    static var enabled: Bool { mode != nil }
    private static var fired = false

    /// Wall-clock seconds at process exec, from the kernel.
    static let processStart: Double? = {
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        guard sysctl(&mib, 4, &info, &size, nil, 0) == 0 else { return nil }
        let tv = info.kp_proc.p_starttime
        return Double(tv.tv_sec) + Double(tv.tv_usec) / 1_000_000
    }()

    static func markFirstPaint() {
        guard enabled, !fired else { return }
        fired = true
        let appearMs = elapsedMs()
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            let paintMs = elapsedMs()
            print("ONAPPEAR_MS=\(fmt(appearMs)) FIRST_PAINT_MS=\(fmt(paintMs))")
            fflush(stdout)
            if mode == "exit" {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { NSApp.terminate(nil) }
            }
        }
        CATransaction.commit()
    }

    private static func elapsedMs() -> Double {
        guard let t0 = processStart else { return -1 }
        return (Date().timeIntervalSince1970 - t0) * 1000
    }

    private static func fmt(_ v: Double) -> String { String(format: "%.1f", v) }
}
