import Cocoa
import FlutterMacOS

/// Everything that Flutter/Dart cannot do on macOS.
/// One MethodChannel, `force/strict`, bidirectional.
///
/// Dart -> Swift : raiseToFront, setLevel, setCollectionBehavior, setRefuseClose,
///                 installLaunchAgent, uninstallLaunchAgent, launchAgentStatus, log
/// Swift -> Dart : onSystemEvent(name, at)
final class StrictMode: NSObject, NSWindowDelegate {

  static let channelName = "force/strict"

  private weak var window: NSWindow?
  private var channel: FlutterMethodChannel?
  private var refuseClose = false

  /// Persisted, wall-clock evidence log. Deliberately outside the app bundle so it
  /// survives rebuilds and so a LaunchAgent-spawned copy writes to the same place.
  private static let logURL: URL = {
    let dir = FileManager.default.homeDirectoryForCurrentUser
      .appendingPathComponent("Documents/projects/force/spikes/strict-mode/evidence")
    try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    return dir.appendingPathComponent("macos-events.log")
  }()

  init(window: NSWindow, messenger: FlutterBinaryMessenger) {
    super.init()
    self.window = window
    self.channel = FlutterMethodChannel(name: Self.channelName, binaryMessenger: messenger)
    self.channel?.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result: result)
    }
    window.delegate = self
    observeLifecycle()
    appendLog("process-start pid=\(ProcessInfo.processInfo.processIdentifier)")
  }

  // MARK: - D8: lifecycle observers (the five v1 never had)

  private func observeLifecycle() {
    let ws = NSWorkspace.shared.notificationCenter
    ws.addObserver(self, selector: #selector(onWake),
                   name: NSWorkspace.didWakeNotification, object: nil)
    ws.addObserver(self, selector: #selector(onSleep),
                   name: NSWorkspace.willSleepNotification, object: nil)
    ws.addObserver(self, selector: #selector(onScreensWake),
                   name: NSWorkspace.screensDidWakeNotification, object: nil)
    ws.addObserver(self, selector: #selector(onScreensSleep),
                   name: NSWorkspace.screensDidSleepNotification, object: nil)
    ws.addObserver(self, selector: #selector(onSessionActive),
                   name: NSWorkspace.sessionDidBecomeActiveNotification, object: nil)

    let nc = NotificationCenter.default
    nc.addObserver(self, selector: #selector(onDidBecomeActive),
                   name: NSApplication.didBecomeActiveNotification, object: nil)
    nc.addObserver(self, selector: #selector(onDayChanged),
                   name: .NSCalendarDayChanged, object: nil)
    nc.addObserver(self, selector: #selector(onClockChanged),
                   name: .NSSystemClockDidChange, object: nil)
    nc.addObserver(self, selector: #selector(onTimeZoneChanged),
                   name: .NSSystemTimeZoneDidChange, object: nil)
  }

  @objc private func onWake()            { emit("NSWorkspace.didWakeNotification") }
  @objc private func onSleep()           { emit("NSWorkspace.willSleepNotification") }
  @objc private func onScreensWake()     { emit("NSWorkspace.screensDidWakeNotification") }
  @objc private func onScreensSleep()    { emit("NSWorkspace.screensDidSleepNotification") }
  @objc private func onSessionActive()   { emit("NSWorkspace.sessionDidBecomeActiveNotification") }
  @objc private func onDidBecomeActive() { emit("NSApplication.didBecomeActiveNotification") }
  @objc private func onDayChanged()      { emit("NSCalendarDayChanged") }
  @objc private func onClockChanged()    { emit("NSSystemClockDidChange") }
  @objc private func onTimeZoneChanged() { emit("NSSystemTimeZoneDidChange") }

  private func emit(_ name: String) {
    let ts = Self.stamp()
    appendLog("event \(name)")
    DispatchQueue.main.async { [weak self] in
      self?.channel?.invokeMethod("onSystemEvent", arguments: ["name": name, "at": ts])
    }
  }

  // MARK: - Method channel

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]
    switch call.method {

    // Q1 — raise self to front, unprompted
    case "raiseToFront":
      let before = NSWorkspace.shared.frontmostApplication?.localizedName ?? "?"
      let mode = args["mode"] as? String ?? "activateIgnoringOtherApps"
      switch mode {
      case "activateIgnoringOtherApps":
        NSApp.activate(ignoringOtherApps: true)
      case "activateModern":
        if #available(macOS 14.0, *) { NSApp.activate() } else { NSApp.activate(ignoringOtherApps: true) }
      case "runningApplication":
        NSRunningApplication.current.activate(options: [.activateAllWindows])
      case "orderFrontRegardless":
        break // window ordering only, no activation at all
      default:
        NSApp.activate(ignoringOtherApps: true)
      }
      window?.makeKeyAndOrderFront(nil)
      window?.orderFrontRegardless()
      // Give AppKit a beat, then report who actually ended up frontmost.
      let deadline = DispatchTime.now() + .milliseconds(600)
      DispatchQueue.main.asyncAfter(deadline: deadline) { [weak self] in
        let after = NSWorkspace.shared.frontmostApplication?.localizedName ?? "?"
        let isActive = NSApp.isActive
        let isKey = self?.window?.isKeyWindow ?? false
        self?.appendLog("raiseToFront mode=\(mode) frontBefore=\(before) frontAfter=\(after) NSApp.isActive=\(isActive) isKeyWindow=\(isKey)")
        result([
          "mode": mode,
          "frontmostBefore": before,
          "frontmostAfter": after,
          "isActive": isActive,
          "isKeyWindow": isKey,
        ])
      }

    // Q2 — window level + Spaces / full-screen behaviour
    case "setLevel":
      let name = args["level"] as? String ?? "normal"
      window?.level = Self.level(named: name)
      appendLog("setLevel \(name) raw=\(window?.level.rawValue ?? 0)")
      result(["level": name, "raw": window?.level.rawValue ?? 0])

    case "setCollectionBehavior":
      var b: NSWindow.CollectionBehavior = []
      if args["canJoinAllSpaces"] as? Bool ?? false { b.insert(.canJoinAllSpaces) }
      if args["fullScreenAuxiliary"] as? Bool ?? false { b.insert(.fullScreenAuxiliary) }
      if args["stationary"] as? Bool ?? false { b.insert(.stationary) }
      if args["ignoresCycle"] as? Bool ?? false { b.insert(.ignoresCycle) }
      if b.isEmpty { b = [.fullScreenPrimary] } // AppKit default for a Flutter window
      window?.collectionBehavior = b
      appendLog("setCollectionBehavior raw=\(b.rawValue)")
      result(["raw": Int(b.rawValue)])

    // Q3 — refuse to close
    case "setRefuseClose":
      refuseClose = args["value"] as? Bool ?? false
      appendLog("setRefuseClose \(refuseClose)")
      result(refuseClose)

    // Q3b — can we also block Cmd-Q? (we test it so we can report where the OS stops us)
    case "setRefuseQuit":
      AppDelegateBridge.refuseQuit = args["value"] as? Bool ?? false
      appendLog("setRefuseQuit \(AppDelegateBridge.refuseQuit)")
      result(AppDelegateBridge.refuseQuit)

    // Q3 — drive the exact AppKit paths the red button and Cmd-Q use.
    case "simulateUserClose":
      window?.performClose(nil)               // identical to clicking the red dot
      let d1 = DispatchTime.now() + .milliseconds(400)
      DispatchQueue.main.asyncAfter(deadline: d1) { [weak self] in
        result(["stillVisible": self?.window?.isVisible ?? false,
                "processAlive": true])
      }

    case "simulateCmdQ":
      // NSApp.terminate is literally what the Quit menu item sends.
      DispatchQueue.main.async { NSApp.terminate(nil) }
      let d2 = DispatchTime.now() + .milliseconds(600)
      DispatchQueue.main.asyncAfter(deadline: d2) { [weak self] in
        self?.appendLog("survived NSApp.terminate (refuseQuit=\(AppDelegateBridge.refuseQuit))")
        result(["survivedTerminate": true,
                "refuseQuit": AppDelegateBridge.refuseQuit])
      }

    // Q4 — LaunchAgent
    case "installLaunchAgent":
      let interval = args["intervalSeconds"] as? Int ?? 120
      result(installLaunchAgent(intervalSeconds: interval))

    case "uninstallLaunchAgent":
      result(uninstallLaunchAgent())

    case "launchAgentStatus":
      result(launchAgentStatus())

    // Q2 decisive variable — a .regular app owns a Dock tile and a menu bar, and
    // AppKit will not put its windows on another app's full-screen Space. An
    // .accessory app can. Switching is legal at runtime.
    case "setActivationPolicy":
      let p = args["policy"] as? String ?? "regular"
      let ok = NSApp.setActivationPolicy(p == "accessory" ? .accessory : .regular)
      appendLog("setActivationPolicy \(p) ok=\(ok)")
      result(["policy": p, "ok": ok])

    // Q2 variant — force a re-order so .canJoinAllSpaces is re-evaluated against
    // whatever Space is currently active (AppKit only assigns Spaces on order-in).
    case "reorder":
      window?.orderOut(nil)
      window?.orderFrontRegardless()
      let deadline = DispatchTime.now() + .milliseconds(500)
      DispatchQueue.main.asyncAfter(deadline: deadline) { [weak self] in
        result([
          "onActiveSpace": self?.window?.isOnActiveSpace ?? false,
          "isVisible": self?.window?.isVisible ?? false,
          "frontmost": NSWorkspace.shared.frontmostApplication?.localizedName ?? "?",
        ])
      }

    case "setFrame":
      let x = args["x"] as? Double ?? 40
      let y = args["y"] as? Double ?? 40
      let w = args["w"] as? Double ?? 900
      let h = args["h"] as? Double ?? 620
      window?.setFrame(NSRect(x: x, y: y, width: w, height: h), display: true)
      result(["frame": "\(window?.frame ?? .zero)"])

    case "frontmost":
      let fa = NSWorkspace.shared.frontmostApplication
      result([
        "frontmost": fa?.localizedName ?? "?",
        "bundleId": fa?.bundleIdentifier ?? "?",
        "selfIsActive": NSApp.isActive,
        "isKeyWindow": window?.isKeyWindow ?? false,
        "isVisible": window?.isVisible ?? false,
        "level": window?.level.rawValue ?? 0,
        "onActiveSpace": window?.isOnActiveSpace ?? false,
      ])

    // Q2 (the shape that actually works) — the gate is NOT the main window.
    // It is a separate borderless NSPanel, created on demand, hosting its own
    // FlutterViewController on a second FlutterEngine.
    case "showGatePanel":
      showGatePanel(fullScreenCover: args["cover"] as? Bool ?? true)
      let deadline = DispatchTime.now() + .milliseconds(700)
      DispatchQueue.main.asyncAfter(deadline: deadline) { [weak self] in
        result([
          "onActiveSpace": self?.gatePanel?.isOnActiveSpace ?? false,
          "isVisible": self?.gatePanel?.isVisible ?? false,
          "level": self?.gatePanel?.level.rawValue ?? 0,
          "frontmost": NSWorkspace.shared.frontmostApplication?.localizedName ?? "?",
        ])
      }

    case "hideGatePanel":
      gatePanel?.orderOut(nil)
      result(nil)

    case "log":
      appendLog("dart " + (args["message"] as? String ?? ""))
      result(nil)

    case "info":
      result([
        "sandboxed": ProcessInfo.processInfo.environment["APP_SANDBOX_CONTAINER_ID"] != nil,
        "bundlePath": Bundle.main.bundlePath,
        "pid": ProcessInfo.processInfo.processIdentifier,
        "logPath": Self.logURL.path,
        "launchedByLaunchd": ProcessInfo.processInfo.environment["FORCE_LAUNCHD"] != nil,
      ])

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - The gate panel (second Flutter engine in a borderless NSPanel)

  private var gatePanel: NSPanel?
  private var gateEngine: FlutterEngine?

  private func showGatePanel(fullScreenCover: Bool) {
    if gatePanel == nil {
      let screen = NSScreen.main ?? NSScreen.screens[0]
      let rect = fullScreenCover
        ? screen.frame
        : NSRect(x: screen.frame.minX + 200, y: screen.frame.minY + 200, width: 900, height: 500)

      let panel = NSPanel(contentRect: rect,
                          styleMask: [.borderless, .nonactivatingPanel],
                          backing: .buffered, defer: false)
      panel.isFloatingPanel = true
      panel.hidesOnDeactivate = false
      panel.level = .screenSaver
      panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
      panel.isOpaque = true
      panel.backgroundColor = .black

      // Second engine so the gate has its own Dart isolate + widget tree.
      let engine = FlutterEngine(name: "gate", project: nil, allowHeadlessExecution: true)
      engine.run(withEntrypoint: "gateMain")
      RegisterGeneratedPlugins(registry: engine)
      let vc = FlutterViewController(engine: engine, nibName: nil, bundle: nil)
      panel.contentViewController = vc
      panel.setFrame(rect, display: true)

      gateEngine = engine
      gatePanel = panel
    }
    gatePanel?.orderFrontRegardless()
    appendLog("showGatePanel onActiveSpace=\(gatePanel?.isOnActiveSpace ?? false)")
  }

  private static func level(named: String) -> NSWindow.Level {
    switch named {
    case "normal":       return .normal
    case "floating":     return .floating
    case "modalPanel":   return .modalPanel
    case "mainMenu":     return .mainMenu
    case "statusBar":    return .statusBar
    case "popUpMenu":    return .popUpMenu
    case "screenSaver":  return .screenSaver
    case "aboveScreenSaver": return NSWindow.Level(rawValue: NSWindow.Level.screenSaver.rawValue + 1)
    default:             return .normal
    }
  }

  // MARK: - NSWindowDelegate (D7: insistent, never a hard lock)

  func windowShouldClose(_ sender: NSWindow) -> Bool {
    appendLog("windowShouldClose refuseClose=\(refuseClose) -> \(!refuseClose)")
    channel?.invokeMethod("onSystemEvent",
                          arguments: ["name": "windowShouldClose(refused=\(refuseClose))",
                                      "at": Self.stamp()])
    return !refuseClose
  }

  // MARK: - LaunchAgent

  private static let agentLabel = "com.clupai.forcespike.strictmode"

  private var plistURL: URL {
    FileManager.default.homeDirectoryForCurrentUser
      .appendingPathComponent("Library/LaunchAgents/\(Self.agentLabel).plist")
  }

  private func installLaunchAgent(intervalSeconds: Int) -> [String: Any] {
    let url = plistURL
    var errors: [String] = []
    do {
      try FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                              withIntermediateDirectories: true)
    } catch { errors.append("mkdir: \(error.localizedDescription)") }

    let dict: [String: Any] = [
      "Label": Self.agentLabel,
      // /usr/bin/open so LaunchServices hands off to a live instance instead of
      // spawning a second GUI process with the same bundle id (v1's lesson).
      "ProgramArguments": ["/usr/bin/open", "-a", Bundle.main.bundlePath],
      "StartInterval": intervalSeconds,
      "RunAtLoad": false,
      "ProcessType": "Interactive",
      "EnvironmentVariables": ["FORCE_LAUNCHD": "1"],
      "StandardOutPath": Self.logURL.deletingLastPathComponent()
        .appendingPathComponent("launchagent.out").path,
      "StandardErrorPath": Self.logURL.deletingLastPathComponent()
        .appendingPathComponent("launchagent.err").path,
    ]

    var wrote = false
    do {
      let data = try PropertyListSerialization.data(fromPropertyList: dict, format: .xml, options: 0)
      try data.write(to: url)
      wrote = true
    } catch {
      errors.append("write: \(error.localizedDescription)")
    }

    var bootstrapStatus: Int32 = -999
    var bootstrapErr = ""
    if wrote {
      let domain = "gui/\(getuid())"
      _ = run(["/bin/launchctl", "bootout", "\(domain)/\(Self.agentLabel)"])
      let r = run(["/bin/launchctl", "bootstrap", domain, url.path])
      bootstrapStatus = r.status
      bootstrapErr = r.err
    }

    appendLog("installLaunchAgent wrote=\(wrote) bootstrap=\(bootstrapStatus) err=\(bootstrapErr) errors=\(errors)")
    return [
      "plistPath": url.path,
      "wrotePlist": wrote,
      "bootstrapStatus": Int(bootstrapStatus),
      "bootstrapStderr": bootstrapErr,
      "errors": errors,
    ]
  }

  private func uninstallLaunchAgent() -> [String: Any] {
    let r = run(["/bin/launchctl", "bootout", "gui/\(getuid())/\(Self.agentLabel)"])
    try? FileManager.default.removeItem(at: plistURL)
    return ["bootoutStatus": Int(r.status), "stderr": r.err]
  }

  private func launchAgentStatus() -> [String: Any] {
    let r = run(["/bin/launchctl", "print", "gui/\(getuid())/\(Self.agentLabel)"])
    return [
      "plistExists": FileManager.default.fileExists(atPath: plistURL.path),
      "printStatus": Int(r.status),
      "print": String(r.out.prefix(2000)),
      "stderr": r.err,
    ]
  }

  @discardableResult
  private func run(_ args: [String]) -> (status: Int32, out: String, err: String) {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: args[0])
    p.arguments = Array(args.dropFirst())
    let o = Pipe(); let e = Pipe()
    p.standardOutput = o; p.standardError = e
    do { try p.run() } catch { return (-1, "", "spawn failed: \(error.localizedDescription)") }
    let od = o.fileHandleForReading.readDataToEndOfFile()
    let ed = e.fileHandleForReading.readDataToEndOfFile()
    p.waitUntilExit()
    return (p.terminationStatus,
            String(data: od, encoding: .utf8) ?? "",
            String(data: ed, encoding: .utf8) ?? "")
  }

  // MARK: - Logging

  private static func stamp() -> String {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    return f.string(from: Date())
  }

  private func appendLog(_ line: String) {
    let text = "\(Self.stamp())  \(line)\n"
    guard let data = text.data(using: .utf8) else { return }
    if let fh = try? FileHandle(forWritingTo: Self.logURL) {
      defer { fh.closeFile() }
      fh.seekToEndOfFile()
      fh.write(data)
    } else {
      try? data.write(to: Self.logURL)
    }
  }
}

/// Static box so the AppDelegate (which owns applicationShouldTerminate) can read
/// the "refuse quit" flag set from Dart.
enum AppDelegateBridge {
  static var refuseQuit = false
}
