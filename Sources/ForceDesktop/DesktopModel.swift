import Foundation
import SwiftCrossUI
import ForceKit

/// Observable app state for the desktop GUI — the counterpart to the macOS
/// `Store` + `SettingsStore` + `RemoteSync` trio, collapsed into one model.
///
/// All policy and persistence stay in ForceKit (`AcknowledgementGate`,
/// `AcknowledgementJournal`, `SettingsStorage`, `SyncEngine`); this type holds
/// the `@Published` mirrors SwiftCrossUI observes and the platform glue:
/// gate recomputation, last-write-wins sync reconciliation, and dirty tracking.
@MainActor
final class DesktopModel: SwiftCrossUI.ObservableObject {
    private let env: DesktopEnvironment

    // MARK: Settings mirror
    @SwiftCrossUI.Published var hasOnboarded: Bool
    @SwiftCrossUI.Published var displayName: String
    @SwiftCrossUI.Published var frequency: Frequency
    @SwiftCrossUI.Published var contractText: String
    @SwiftCrossUI.Published var motivation: String
    @SwiftCrossUI.Published var reflection: String
    @SwiftCrossUI.Published var nonNegotiables: [NonNegotiable]

    // MARK: Gate + journal
    @SwiftCrossUI.Published var gateOpen = false
    @SwiftCrossUI.Published var todayAction = ""
    @SwiftCrossUI.Published var checklistState: [String: Bool] = [:]

    /// Reset each launch; backs the `everyLaunch` / `onLogin` schedules.
    private var sessionAcknowledged = false

    // MARK: Sync
    @SwiftCrossUI.Published var baseURL: String
    @SwiftCrossUI.Published var anonKey: String
    @SwiftCrossUI.Published var email: String?
    /// Human-readable one-line sync status for the Settings panel.
    @SwiftCrossUI.Published var syncStatus = ""

    private var localDirty: Bool
    private var localUpdatedAt: Double

    init() {
        let env = DesktopEnvironment()
        self.env = env
        let s = env.settings

        hasOnboarded = s.hasOnboarded
        displayName = s.displayName
        frequency = s.frequency
        contractText = s.contractText
        motivation = s.motivation
        reflection = s.reflection
        nonNegotiables = s.nonNegotiables

        baseURL = env.store.string(forKey: DesktopEnvironment.Keys.baseURL) ?? ""
        anonKey = env.store.string(forKey: DesktopEnvironment.Keys.anonKey) ?? ""
        localDirty = env.store.bool(forKey: DesktopEnvironment.Keys.localDirty)
        localUpdatedAt = env.store.double(forKey: DesktopEnvironment.Keys.localUpdatedAt)
        email = env.engine.session?.email

        if let ack = env.journal.acknowledgement() { todayAction = ack.action }
        checklistState = env.journal.loadChecklist(items: nonNegotiables)
        recomputeGate()
    }

    // MARK: Gate

    func recomputeGate() {
        gateOpen = AcknowledgementGate.isOpen(
            lastAcknowledgedMs: env.journal.lastAcknowledgedMs,
            frequency: frequency,
            sessionAcknowledged: sessionAcknowledged
        )
    }

    // MARK: Acknowledgement

    /// Signs today's contract with the given action and opens the gate.
    func confirm(action: String) {
        let trimmed = action.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        env.journal.confirm(action: trimmed, items: nonNegotiables)
        checklistState = env.journal.loadChecklist(items: nonNegotiables)
        sessionAcknowledged = true
        todayAction = trimmed
        gateOpen = true
    }

    /// Edits today's confirmed action in place.
    func updateTodayAction(_ newAction: String) {
        if let stored = env.journal.updateTodayAction(newAction, currentAction: todayAction) {
            todayAction = stored
        }
    }

    // MARK: Checklist

    func toggle(_ id: String) {
        checklistState[id, default: false].toggle()
        env.journal.persistChecklist(checklistState, for: AppDate.todayKey())
    }

    var completedCount: Int { nonNegotiables.filter { checklistState[$0.id] == true }.count }
    var totalCount: Int { nonNegotiables.count }

    func history() -> [HistoryEntry] { env.journal.history() }

    // MARK: Onboarding / settings

    func setDisplayName(_ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespaces)
        displayName = trimmed
        env.settings.displayName = trimmed
    }

    func setFrequency(_ value: Frequency) {
        frequency = value
        env.settings.frequency = value
        recomputeGate()
    }

    func completeOnboarding() {
        hasOnboarded = true
        env.settings.hasOnboarded = true
    }

    // MARK: Sync

    var effectiveURL: String {
        let override = baseURL.trimmingCharacters(in: .whitespaces)
        return override.isEmpty ? SupabaseConfig.url : override
    }
    var effectiveAnonKey: String {
        let override = anonKey.trimmingCharacters(in: .whitespaces)
        return override.isEmpty ? SupabaseConfig.anonKey : override
    }
    var isConfigured: Bool { !effectiveURL.isEmpty && !effectiveAnonKey.isEmpty }
    var isLoggedIn: Bool { env.engine.isLoggedIn }

    /// Persists the user-entered connection overrides so the engine's lazy
    /// client factory picks them up.
    func saveConnection() {
        env.store.set(baseURL.trimmingCharacters(in: .whitespaces), forKey: DesktopEnvironment.Keys.baseURL)
        env.store.set(anonKey.trimmingCharacters(in: .whitespaces), forKey: DesktopEnvironment.Keys.anonKey)
    }

    /// Called once on launch — refreshes content if we have a session.
    func launchSync() async {
        guard isConfigured, isLoggedIn else { return }
        await syncNow()
    }

    func login(email rawEmail: String, password: String) async {
        saveConnection()
        guard isConfigured else { syncStatus = "Enter your Supabase URL and anon key first."; return }
        let email = rawEmail.trimmingCharacters(in: .whitespaces)
        guard !email.isEmpty, !password.isEmpty else {
            syncStatus = "Enter your email and password."; return
        }
        syncStatus = "Signing in…"
        do {
            let session = try await env.engine.login(email: email, password: password)
            self.email = session.email ?? email
            await syncNow()
        } catch {
            syncStatus = "Login failed: \(message(for: error))"
        }
    }

    func logout() {
        email = nil
        syncStatus = "Logged out."
        Task { await env.engine.logout() }
    }

    /// Reconciles local and cloud copies with last-write-wins.
    func syncNow() async {
        guard isConfigured, isLoggedIn else { return }
        syncStatus = "Syncing…"
        do {
            let cloud = try await env.engine.fetchContent()
            let cloudMs = PostgresTimestamp.epochMs(cloud.updatedAt)
            if localDirty && localUpdatedAt > cloudMs {
                try await push()
            } else {
                apply(cloud)
                localUpdatedAt = cloudMs
                env.store.set(cloudMs, forKey: DesktopEnvironment.Keys.localUpdatedAt)
            }
            clearDirty()
            syncStatus = "Synced."
        } catch {
            syncStatus = "Sync failed: \(message(for: error))"
        }
    }

    private func push() async throws {
        try await env.engine.pushContent(
            contractMd: contractText,
            goals: nonNegotiables.map { RemoteGoal(id: $0.id, label: $0.label) }
        )
    }

    /// Applies a cloud row to local state (cloud → local only).
    private func apply(_ c: RemoteContent) {
        let contract = c.contractMd.trimmingCharacters(in: .whitespacesAndNewlines)
        if !contract.isEmpty {
            contractText = c.contractMd
            env.settings.contractText = c.contractMd
        }
        if !c.goals.isEmpty {
            let items = c.goals.map { NonNegotiable(id: $0.id, label: $0.label) }
            nonNegotiables = items
            env.settings.nonNegotiables = items
            checklistState = env.journal.reconcileChecklist(checklistState, items: items)
        }
        let quotes = c.quotes.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        if let quote = quotes.randomElement() {
            motivation = quote
            env.settings.motivation = quote
        }
        reflection = c.reflection
        env.settings.reflection = c.reflection
    }

    private func clearDirty() {
        localDirty = false
        env.store.set(false, forKey: DesktopEnvironment.Keys.localDirty)
    }

    private func message(for error: Error) -> String {
        switch error {
        case let e as SyncError: return e.message
        case let e as HTTPStatusError: return e.message
        default: return (error as NSError).localizedDescription
        }
    }
}
