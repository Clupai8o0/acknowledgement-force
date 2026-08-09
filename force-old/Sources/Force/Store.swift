import Foundation
import SwiftUI
import AppKit
import ForceKit

/// Observable façade over ForceKit's ``AcknowledgementJournal`` and
/// ``AcknowledgementGate`` for the macOS UI.
///
/// All policy and persistence live in ForceKit; this type adds what's
/// macOS-specific: `@Published` state for SwiftUI, re-checking the gate when
/// the app activates (the hourly launchd `open` lands as an activation), and
/// the Application Support acknowledgement log.
@MainActor
final class Store: ObservableObject {
    static let shared = Store()

    private let journal = AcknowledgementJournal(store: UserDefaultsKeyValueStore())

    @Published var checklistState: [String: Bool] = [:]
    @Published var todayAction: String = ""

    /// True when the current schedule period is already acknowledged — the
    /// app shows the dashboard rather than the locked contract.
    @Published var gateOpen: Bool = false

    /// Reset each process launch; backs the "every launch" / "on login" gate.
    private var sessionAcknowledged = false

    init() {
        if let ack = journal.acknowledgement() {
            todayAction = ack.action
        }
        checklistState = journal.loadChecklist(items: SettingsStore.shared.nonNegotiables)
        recomputeGate()

        // Re-check the gate whenever the app is activated. The hourly launchd
        // job uses `open`, which just brings the running instance forward —
        // without this, the contract never replaces the dashboard mid-session.
        NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.recomputeGate() }
        }

        // Belt-and-suspenders for the case where Force stays frontmost across a
        // schedule boundary: no activation transition fires, so the observer
        // above never runs. A periodic tick guarantees the gate flips on time.
        Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.recomputeGate() }
        }
    }

    // MARK: Period gate

    /// Re-evaluates whether the latest acknowledgement still satisfies the
    /// schedule and publishes the result.
    func recomputeGate() {
        gateOpen = AcknowledgementGate.isOpen(
            lastAcknowledgedMs: journal.lastAcknowledgedMs,
            frequency: SettingsStore.shared.frequency,
            sessionAcknowledged: sessionAcknowledged
        )
    }

    // MARK: Acknowledgement

    /// Signs today's contract with the given action and opens the gate.
    func confirm(action: String) {
        journal.confirm(action: action, items: SettingsStore.shared.nonNegotiables)
        checklistState = journal.loadChecklist(items: SettingsStore.shared.nonNegotiables)
        recordToLog()
        sessionAcknowledged = true
        todayAction = action
        gateOpen = true
    }

    /// Edits today's confirmed action in place (live value, stored
    /// acknowledgement, and today's history entry).
    func updateTodayAction(_ newAction: String) {
        if let stored = journal.updateTodayAction(newAction, currentAction: todayAction) {
            todayAction = stored
        }
    }

    // MARK: Checklist

    /// Keeps checklist state in step with the editable item list: drops removed
    /// items, defaults newly added ones to unchecked. Called when items change.
    func syncChecklist() {
        checklistState = journal.reconcileChecklist(
            checklistState, items: SettingsStore.shared.nonNegotiables)
    }

    func toggle(_ id: String) {
        checklistState[id, default: false].toggle()
        journal.persistChecklist(checklistState, for: AppDate.todayKey())
    }

    var completedCount: Int {
        SettingsStore.shared.nonNegotiables.filter { checklistState[$0.id] == true }.count
    }
    var totalCount: Int { SettingsStore.shared.nonNegotiables.count }

    // MARK: History

    func loadHistory() -> [HistoryEntry] {
        journal.history()
    }

    // MARK: Acknowledgement log (mirrors the original Tauri backend record)

    private func recordToLog() {
        let fm = FileManager.default
        guard let dir = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("Force", isDirectory: true) else { return }
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        let file = dir.appendingPathComponent("acknowledgements.log")
        let line = "acknowledged_at_ms=\(Int(Date().timeIntervalSince1970 * 1000))\n"
        guard let data = line.data(using: .utf8) else { return }
        if let handle = try? FileHandle(forWritingTo: file) {
            defer { try? handle.close() }
            handle.seekToEndOfFile()
            handle.write(data)
        } else {
            try? data.write(to: file)
        }
    }
}
