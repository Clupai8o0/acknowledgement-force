import Flutter
import UIKit
import UserNotifications

#if canImport(FamilyControls)
import FamilyControls
#endif

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {

  private var channel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    log("didFinishLaunching")
    NotificationCenter.default.addObserver(
      self, selector: #selector(bg), name: UIApplication.didEnterBackgroundNotification, object: nil)
    NotificationCenter.default.addObserver(
      self, selector: #selector(fg), name: UIApplication.willEnterForegroundNotification, object: nil)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  @objc private func bg() { log("UIApplication.didEnterBackground") }
  @objc private func fg() { log("UIApplication.willEnterForeground") }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let messenger = (window?.rootViewController as? FlutterViewController)?.binaryMessenger
      ?? engineBridge.pluginRegistry.registrar(forPlugin: "StrictMode")!.messenger()
    channel = FlutterMethodChannel(name: "force/strict", binaryMessenger: messenger)
    channel?.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result: result)
    }
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]
    switch call.method {

    case "info":
      result([
        "logPath": Self.logURL.path,
        "state": "\(UIApplication.shared.applicationState.rawValue)",
        "familyControlsCompiled": Self.familyControlsAvailable,
      ])

    // Q9 — the only legitimate way to get the user's attention from the background.
    case "scheduleNotification":
      let secs = args["seconds"] as? Double ?? 8
      UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, err in
        self.log("notification auth granted=\(granted) err=\(String(describing: err))")
        let c = UNMutableNotificationContent()
        c.title = "Force"
        c.body = "The day hasn't settled. Open Force."
        c.sound = .default
        if #available(iOS 15.0, *) {
          // strongest level available without the Critical Alerts entitlement
          c.interruptionLevel = .timeSensitive
        }
        let req = UNNotificationRequest(
          identifier: "gate",
          content: c,
          trigger: UNTimeIntervalNotificationTrigger(timeInterval: secs, repeats: false))
        UNUserNotificationCenter.current().add(req) { e in
          self.log("scheduled notification in \(secs)s err=\(String(describing: e))")
        }
      }
      result(["scheduledIn": secs])

    // Q9 — the thing the user actually wants. There is no API; this is the closest
    // anyone gets, and it is a no-op unless the app is already foreground.
    case "tryRaiseToFront":
      var attempts: [String: String] = [:]
      // 1. opening our own URL scheme from inside ourselves
      if let url = URL(string: "strictmode://gate") {
        let can = UIApplication.shared.canOpenURL(url)
        attempts["canOpenOwnScheme"] = "\(can)"
        UIApplication.shared.open(url, options: [:]) { ok in
          self.log("open(own scheme) -> \(ok)")
        }
      }
      // 2. there is no UIApplication API to activate/foreground self.
      attempts["activateAPI"] = "none exists on UIKit"
      attempts["applicationState"] = "\(UIApplication.shared.applicationState.rawValue)"
      log("tryRaiseToFront \(attempts)")
      result(attempts)

    // Q9 — Screen Time / FamilyControls availability check.
    case "familyControls":
      #if canImport(FamilyControls)
      if #available(iOS 16.0, *) {
        Task {
          var out: [String: String] = ["compiled": "true"]
          out["statusBefore"] = "\(AuthorizationCenter.shared.authorizationStatus.rawValue)"
          do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            out["request"] = "granted"
          } catch {
            out["request"] = "FAILED: \(error)"
          }
          out["statusAfter"] = "\(AuthorizationCenter.shared.authorizationStatus.rawValue)"
          self.log("familyControls \(out)")
          result(out)
        }
      } else {
        result(["compiled": "true", "request": "needs iOS 16"])
      }
      #else
      result(["compiled": "false", "request": "FamilyControls not importable"])
      #endif

    case "readLog":
      result((try? String(contentsOf: Self.logURL, encoding: .utf8)) ?? "<empty>")

    case "log":
      log("dart " + (args["message"] as? String ?? ""))
      result(nil)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private static var familyControlsAvailable: Bool {
    #if canImport(FamilyControls)
    return true
    #else
    return false
    #endif
  }

  private static let logURL: URL = {
    let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    return dir.appendingPathComponent("ios-events.log")
  }()

  private func log(_ s: String) {
    let f = DateFormatter(); f.dateFormat = "HH:mm:ss.SSS"
    let line = "\(f.string(from: Date()))  \(s)\n"
    NSLog("FORCE %@", line)
    guard let d = line.data(using: .utf8) else { return }
    if let fh = try? FileHandle(forWritingTo: Self.logURL) {
      defer { fh.closeFile() }
      fh.seekToEndOfFile(); fh.write(d)
    } else {
      try? d.write(to: Self.logURL)
    }
  }
}
