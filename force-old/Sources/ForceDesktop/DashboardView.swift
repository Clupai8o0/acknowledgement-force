import Foundation
import SwiftCrossUI
import ForceKit

/// The gate-open dashboard: checklist sidebar + today's action, motivation,
/// the contract, history, and a settings/sync panel. Desktop port of the macOS
/// `AppView` (+ a compact Settings panel folded in).
struct DashboardView: View {
    @Environment(DesktopModel.self) var model

    @State var editingAction = false
    @State var actionDraft = ""
    @State var showHistory = false
    @State var showSettings = false

    // Settings/sync form fields.
    @State var urlField = ""
    @State var keyField = ""
    @State var emailField = ""
    @State var passwordField = ""

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            sidebar
            ScrollView {
                VStack(alignment: .leading, spacing: Space.xl) {
                    headerBar
                    actionCard
                    reflectionSection
                    motivationSection
                    contractSection
                    historySection
                    settingsPanel
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Space.section)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Ink.base)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            urlField = model.baseURL
            keyField = model.anonKey
        }
    }

    // MARK: Sidebar

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: Space.lg) {
            HStack {
                Text("DAILY NON-NEGOTIABLES")
                    .font(Type.headingMD)
                    .foregroundColor(Ink.ink)
                Spacer()
                Text("\(model.completedCount)/\(model.totalCount)")
                    .font(Type.captionSM)
                    .foregroundColor(Ink.ink)
                    .padding(.horizontal, Space.md)
                    .padding(.vertical, Space.xs)
                    .background(Ink.containerHigh)
                    .cornerRadius(Radius.sm)
            }
            VStack(alignment: .leading, spacing: Space.xs) {
                ForEach(model.nonNegotiables, id: \.id) { item in
                    checklistRow(item)
                }
            }
            Spacer()
        }
        .padding(Space.xl)
        .frame(width: 340)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Ink.containerLow)
    }

    private func checklistRow(_ item: NonNegotiable) -> some View {
        Toggle(item.label, isOn: Binding(
            get: { model.checklistState[item.id] ?? false },
            set: { newValue in
                let current = model.checklistState[item.id] ?? false
                if current != newValue { model.toggle(item.id) }
            }
        ))
        .padding(.vertical, Space.xs)
    }

    // MARK: Header

    private var welcomeTitle: String {
        let name = model.displayName.trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? "WELCOME BACK" : "WELCOME BACK, \(name.uppercased())"
    }

    private var headerBar: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: Space.xs) {
                Text(welcomeTitle).font(Type.display(34)).foregroundColor(Ink.ink)
                Text(AppDate.longToday()).font(Type.captionMD).foregroundColor(Ink.mute)
            }
            Spacer()
            HStack(spacing: Space.sm) {
                GhostButton(title: showSettings ? "Close Settings" : "Settings") {
                    showSettings = !showSettings
                }
                GhostButton(title: "Exit") { exit(0) }
            }
        }
    }

    // MARK: Today's action

    private var actionCard: some View {
        VStack(alignment: .leading, spacing: Space.md) {
            HStack {
                Text("TODAY'S HIGHEST-LEVERAGE ACTION")
                    .font(Type.captionSM)
                    .foregroundColor(Ink.mute)
                Spacer()
                GhostButton(title: editingAction ? "Save" : "Edit") {
                    if editingAction {
                        model.updateTodayAction(actionDraft)
                        editingAction = false
                    } else {
                        actionDraft = model.todayAction
                        editingAction = true
                    }
                }
            }
            if editingAction {
                TextField("What is the ONE thing you must do today?", text: $actionDraft)
                    .fieldBox()
            } else {
                Text(model.todayAction.isEmpty ? "—" : model.todayAction)
                    .font(Type.headingLG)
                    .foregroundColor(Ink.ink)
            }
        }
        .card()
    }

    // MARK: Reflection (web-edited)

    @ViewBuilder private var reflectionSection: some View {
        if !model.reflection.trimmingCharacters(in: .whitespaces).isEmpty {
            VStack(alignment: .leading, spacing: Space.sm) {
                Text("REFLECTION").font(Type.captionSM).foregroundColor(Ink.mute)
                Text(model.reflection).font(Type.bodyMD).foregroundColor(Ink.ash)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Space.xl)
            .background(Ink.containerLow)
            .cornerRadius(Radius.lg)
        }
    }

    // MARK: Motivation

    @ViewBuilder private var motivationSection: some View {
        if !model.motivation.trimmingCharacters(in: .whitespaces).isEmpty {
            Text("“\(model.motivation)”")
                .font(Type.headingLG)
                .foregroundColor(Ink.ash)
        }
    }

    // MARK: Contract

    private var contractSection: some View {
        VStack(alignment: .leading, spacing: Space.md) {
            Text("YOUR CONTRACT").font(Type.captionSM).foregroundColor(Ink.mute)
            VStack(alignment: .leading, spacing: Space.sm) {
                ForEach(indexedBlocks(from: model.contractText, name: model.displayName), id: \.id) { item in
                    contractBlockView(item.block)
                }
            }
        }
    }

    // MARK: History

    @ViewBuilder private var historySection: some View {
        VStack(alignment: .leading, spacing: Space.sm) {
            GhostButton(
                title: showHistory ? "Hide Past Actions" : "View Past Actions",
                color: Ink.ink
            ) { showHistory = !showHistory }
            if showHistory {
                VStack(alignment: .leading, spacing: Space.xs) {
                    ForEach(model.history(), id: \.id) { entry in
                        HStack(spacing: Space.md) {
                            Text(AppDate.short(entry.date))
                                .font(Type.captionMD)
                                .foregroundColor(Ink.mute)
                                .frame(width: 110, alignment: .leading)
                            Text(entry.action).font(Type.bodyMD).foregroundColor(Ink.ink)
                            Spacer()
                        }
                    }
                }
            }
        }
    }

    // MARK: Settings + sync

    @ViewBuilder private var settingsPanel: some View {
        if showSettings {
            VStack(alignment: .leading, spacing: Space.lg) {
                scheduleSection
                syncSection
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Space.xl)
            .background(Ink.containerLow)
            .cornerRadius(Radius.lg)
        }
    }

    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: Space.sm) {
            Text("RE-LOCK SCHEDULE").font(Type.captionSM).foregroundColor(Ink.mute)
            VStack(spacing: Space.xs) {
                ForEach(Frequency.allCases, id: \.id) { freq in
                    FrequencyRow(
                        frequency: freq,
                        selected: freq == model.frequency,
                        action: { model.setFrequency(freq) }
                    )
                }
            }
        }
    }

    private var syncSection: some View {
        VStack(alignment: .leading, spacing: Space.sm) {
            Text("CLOUD SYNC").font(Type.captionSM).foregroundColor(Ink.mute)
            if model.isLoggedIn {
                Text("Signed in as \(model.email ?? "unknown").")
                    .font(Type.bodyMD).foregroundColor(Ink.ink)
                HStack(spacing: Space.md) {
                    PrimaryButton(title: "Sync now") { Task { await model.syncNow() } }
                    GhostButton(title: "Log out") { model.logout() }
                }
            } else {
                TextField("Supabase URL", text: $urlField).fieldBox()
                TextField("Anon key", text: $keyField).fieldBox()
                TextField("Email", text: $emailField).fieldBox()
                SecureField("Password", text: $passwordField).fieldBox()
                PrimaryButton(title: "Sign in") {
                    model.baseURL = urlField
                    model.anonKey = keyField
                    Task { await model.login(email: emailField, password: passwordField) }
                }
            }
            if !model.syncStatus.isEmpty {
                Text(model.syncStatus).font(Type.captionMD).foregroundColor(Ink.mute)
            }
        }
    }
}
