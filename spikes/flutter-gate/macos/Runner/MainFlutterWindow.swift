import Cocoa
import FlutterMacOS

/// Window shell for the spike.
///
/// Fixed 960x640, hidden titlebar, base-colour background — matched to the
/// SwiftUI and Tauri builds so the three screens are the same size on screen.
///
/// Also hosts the cold-start instrumentation: `t0` is the kernel's record of
/// when this process was `exec`d, so dyld, the Flutter engine bring-up and the
/// Dart VM snapshot load are all inside the number. Dart calls back over
/// `gate/instrument` once the first frame has been rasterised.
class MainFlutterWindow: NSWindow {
  private static let width: CGFloat = 960
  private static let height: CGFloat = 640

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController
    self.setContentSize(NSSize(width: MainFlutterWindow.width, height: MainFlutterWindow.height))
    self.styleMask.remove(.resizable)
    self.title = "The Evening Gate"
    self.titlebarAppearsTransparent = true
    self.titleVisibility = .hidden
    self.isMovableByWindowBackground = true
    self.backgroundColor = NSColor(srgbRed: 0x14 / 255.0, green: 0x15 / 255.0, blue: 0x15 / 255.0, alpha: 1)
    self.appearance = NSAppearance(named: .darkAqua)
    self.center()

    RegisterGeneratedPlugins(registry: flutterViewController)
    Instrument.attach(to: flutterViewController)

    // Lets the measurement scripts grab this exact window with
    // `screencapture -l` while sibling spike apps are on screen too.
    if ProcessInfo.processInfo.environment["GATE_FRAMES"] != nil {
      DispatchQueue.main.async {
        print("WINDOW_ID=\(self.windowNumber)")
        fflush(stdout)
      }
    }

    super.awakeFromNib()
  }
}

enum Instrument {
  private static let mode = ProcessInfo.processInfo.environment["GATE_MEASURE"]

  /// Wall-clock seconds at process exec, straight from the kernel.
  private static let processStart: Double? = {
    var info = kinfo_proc()
    var size = MemoryLayout<kinfo_proc>.stride
    var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
    guard sysctl(&mib, 4, &info, &size, nil, 0) == 0 else { return nil }
    let tv = info.kp_proc.p_starttime
    return Double(tv.tv_sec) + Double(tv.tv_usec) / 1_000_000
  }()

  static func attach(to controller: FlutterViewController) {
    let channel = FlutterMethodChannel(
      name: "gate/instrument",
      binaryMessenger: controller.engine.binaryMessenger)
    channel.setMethodCallHandler { call, result in
      result(nil)
      guard mode != nil, let t0 = processStart else { return }
      let ms = (Date().timeIntervalSince1970 - t0) * 1000
      switch call.method {
      case "firstFrame":  // Dart build + layout of frame 1 complete
        print(String(format: "FIRST_FRAME_MS=%.1f", ms))
        fflush(stdout)
      case "firstPaint":  // frame 1 rasterised and handed to the compositor
        print(String(format: "FIRST_PAINT_MS=%.1f", ms))
        fflush(stdout)
        if mode == "exit" {
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { NSApp.terminate(nil) }
        }
      default:
        break
      }
    }
  }
}
