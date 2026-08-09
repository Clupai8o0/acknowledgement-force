import SwiftUI
import ForceKit

// MARK: - Settings sheet

struct SettingsView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var settings: SettingsStore

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("SETTINGS")
                    .font(Type.headingXL)
                    .foregroundStyle(Ink.ink)
                Spacer()
                Button("Done") { isPresented = false }
                    .buttonStyle(GhostTextStyle(color: Ink.mute))
            }
            .padding(.horizontal, Space.section)
            .padding(.top, Space.section)
            .padding(.bottom, Space.xl)
            .background(Ink.containerLow)

            ScrollView {
                VStack(alignment: .leading, spacing: Space.section) {
                    ProfileSection()
                    AppearanceSection()
                    ScheduleSection()
                    SyncSection()
                    MessagesSection()
                    NonNegotiablesSection()
                    EmergencyStopSection()
                }
                .padding(.horizontal, Space.section)
                .padding(.vertical, Space.xl)
            }
        }
        .frame(width: 760, height: 680)
        .background(Ink.base)
        .onDisappear { Task { await RemoteSync.shared.pushIfDirty() } }
    }
}

// MARK: - Reusable section scaffold

struct SectionHeader: View {
    let kicker: String
    let title: String
    var body: some View {
        VStack(alignment: .leading, spacing: Space.xs) {
            Text(kicker)
                .font(Type.captionSM)
                .tracking(1.0)
                .foregroundStyle(Ink.mute)
            Text(title)
                .font(Type.headingLG)
                .foregroundStyle(Ink.ink)
        }
    }
}

// MARK: - Profile

struct ProfileSection: View {
    @EnvironmentObject var settings: SettingsStore

    var body: some View {
        VStack(alignment: .leading, spacing: Space.lg) {
            SectionHeader(kicker: "00 — PROFILE", title: "Your name")

            VStack(alignment: .leading, spacing: Space.sm) {
                Text("DISPLAY NAME")
                    .font(Type.captionSM)
                    .tracking(1.0)
                    .foregroundStyle(Ink.mute)
                Text("Used in your contract wherever {{NAME}} appears.")
                    .font(Type.captionMD)
                    .foregroundStyle(Ink.mute)
                TextField("e.g. Jane Smith", text: $settings.displayName)
                    .textFieldStyle(.plain)
                    .font(Type.bodyMD)
                    .foregroundStyle(Ink.ink)
                    .padding(.horizontal, Space.md)
                    .frame(height: 44)
                    .background(Ink.containerHigh, in: RoundedRectangle(cornerRadius: Radius.md))
            }
        }
    }
}

// MARK: - Appearance

struct AppearanceSection: View {
    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        VStack(alignment: .leading, spacing: Space.lg) {
            SectionHeader(kicker: "01 — APPEARANCE", title: "Theme & colors")

            HStack(spacing: Space.md) {
                ForEach(AppearanceMode.allCases) { mode in
                    SegmentChip(
                        label: mode.label,
                        selected: theme.mode == mode,
                        action: { theme.mode = mode }
                    )
                }
            }

            VStack(spacing: Space.md) {
                colorRow("Page", \.base)
                colorRow("Surface", \.containerHigh)
                colorRow("Text", \.ink)
                colorRow("Muted text", \.mute)
                colorRow("Outline", \.outline)
            }
            .padding(Space.lg)
            .background(Ink.containerLow, in: RoundedRectangle(cornerRadius: Radius.lg))

            Button("Reset \(theme.editingIsDark ? "dark" : "light") colors") {
                theme.resetActive()
            }
            .buttonStyle(GhostTextStyle(color: Ink.mute))
        }
    }

    private func colorRow(_ label: String, _ keyPath: WritableKeyPath<Theme, UInt32>) -> some View {
        HStack {
            Text(label)
                .font(Type.bodyMD)
                .foregroundStyle(Ink.charcoal)
            Spacer()
            ColorPicker("", selection: colorBinding(keyPath), supportsOpacity: false)
                .labelsHidden()
        }
    }

    private func colorBinding(_ keyPath: WritableKeyPath<Theme, UInt32>) -> Binding<Color> {
        Binding(
            get: {
                let t = theme.editingIsDark ? theme.darkTheme : theme.lightTheme
                return Color(rgb: t[keyPath: keyPath])
            },
            set: { newValue in theme.updateActive { $0[keyPath: keyPath] = newValue.rgbHex } }
        )
    }
}

// MARK: - Schedule

struct ScheduleSection: View {
    @EnvironmentObject var settings: SettingsStore

    var body: some View {
        VStack(alignment: .leading, spacing: Space.lg) {
            SectionHeader(kicker: "02 — SCHEDULE", title: "How often Force locks in")

            VStack(spacing: Space.sm) {
                ForEach(Frequency.allCases) { freq in
                    RadioRow(
                        title: freq.label,
                        detail: freq.detail,
                        selected: settings.frequency == freq,
                        action: { settings.frequency = freq }
                    )
                }
            }
            .padding(Space.lg)
            .background(Ink.containerLow, in: RoundedRectangle(cornerRadius: Radius.lg))

            Toggle(isOn: $settings.autoLaunch) {
                VStack(alignment: .leading, spacing: Space.xxs) {
                    Text("Auto-launch on this schedule")
                        .font(Type.bodyStrong)
                        .foregroundStyle(Ink.ink)
                    Text("Installs a LaunchAgent in ~/Library/LaunchAgents so Force opens on login and on the chosen interval.")
                        .font(Type.captionMD)
                        .foregroundStyle(Ink.mute)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .toggleStyle(.switch)
            .tint(Ink.ink)
        }
    }
}

// MARK: - Messages

struct MessagesSection: View {
    @EnvironmentObject var settings: SettingsStore

    var body: some View {
        VStack(alignment: .leading, spacing: Space.lg) {
            SectionHeader(kicker: "04 — WORDS", title: "Your contract & quote")

            editorField(
                label: "DASHBOARD QUOTE",
                hint: "Shown on the home screen. Keep it short.",
                text: $settings.motivation,
                minHeight: 64
            )

            editorField(
                label: "DAILY CONTRACT",
                hint: "Markdown: # heading, --- rule, 1. numbered, - bullet, [ ] checkbox, **bold**. {{DATE}} fills in today.",
                text: $settings.contractText,
                minHeight: 280
            )

            Button("Reset contract to default") {
                settings.contractText = Contract.defaultMarkdown
            }
            .buttonStyle(GhostTextStyle(color: Ink.mute))
        }
    }

    private func editorField(label: String, hint: String, text: Binding<String>, minHeight: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: Space.sm) {
            Text(label)
                .font(Type.captionSM)
                .tracking(1.0)
                .foregroundStyle(Ink.mute)
            Text(hint)
                .font(Type.captionMD)
                .foregroundStyle(Ink.mute)
                .fixedSize(horizontal: false, vertical: true)
            TextEditor(text: text)
                .font(Type.bodyMD)
                .foregroundStyle(Ink.ink)
                .scrollContentBackground(.hidden)
                .padding(Space.md)
                .frame(minHeight: minHeight)
                .background(Ink.containerHigh, in: RoundedRectangle(cornerRadius: Radius.md))
        }
    }
}

// MARK: - Daily non-negotiables

struct NonNegotiablesSection: View {
    @EnvironmentObject var settings: SettingsStore

    var body: some View {
        VStack(alignment: .leading, spacing: Space.lg) {
            SectionHeader(kicker: "05 — CHECKLIST", title: "Daily non-negotiables")

            VStack(spacing: Space.sm) {
                ForEach($settings.nonNegotiables) { $item in
                    HStack(spacing: Space.md) {
                        TextField("Item", text: $item.label)
                        .textFieldStyle(.plain)
                        .font(Type.bodyMD)
                        .foregroundStyle(Ink.ink)
                        .padding(.horizontal, Space.md)
                        .frame(height: 44)
                        .background(Ink.bright, in: RoundedRectangle(cornerRadius: Radius.md))

                        Button {
                            settings.nonNegotiables.removeAll { $0.id == item.id }
                        } label: {
                            Image(systemName: "minus.circle")
                                .foregroundStyle(Ink.mute)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(Space.lg)
            .background(Ink.containerLow, in: RoundedRectangle(cornerRadius: Radius.lg))

            HStack(spacing: Space.lg) {
                Button("Add item") {
                    settings.nonNegotiables.append(
                        NonNegotiable(id: UUID().uuidString, label: "")
                    )
                }
                .buttonStyle(SecondaryPillStyle())

                Button("Reset to default") {
                    settings.nonNegotiables = DefaultCopy.nonNegotiables
                }
                .buttonStyle(GhostTextStyle(color: Ink.mute))
            }
        }
    }
}

// MARK: - Sync (Supabase)

struct SyncSection: View {
    static let signupURL = URL(string: "https://force.clupai.com/signup")!

    @EnvironmentObject var remote: RemoteSync
    @State private var email = ""
    @State private var password = ""
    @State private var showConfig = false

    var body: some View {
        VStack(alignment: .leading, spacing: Space.lg) {
            SectionHeader(kicker: "03 — SYNC", title: "Edit from anywhere")

            Text("Sign in to the web editor's account to pull your contract, quotes, goals and reflection onto this Mac. Changes sync on launch.")
                .font(Type.captionMD)
                .foregroundStyle(Ink.mute)
                .fixedSize(horizontal: false, vertical: true)

            if !remote.isConfigured || showConfig {
                VStack(spacing: Space.sm) {
                    field("Supabase URL", text: $remote.baseURL, placeholder: "https://xxxx.supabase.co")
                    field("Anon public key", text: $remote.anonKey, placeholder: "eyJ…")
                }
                .padding(Space.lg)
                .background(Ink.containerLow, in: RoundedRectangle(cornerRadius: Radius.lg))
            }

            if remote.isConfigured {
                if remote.isLoggedIn {
                    loggedIn
                } else {
                    login
                }
            }

            statusLine
        }
    }

    @ViewBuilder private var login: some View {
        VStack(spacing: Space.sm) {
            field("Email", text: $email, placeholder: "you@example.com")
            secureField("Password", text: $password)
            HStack(spacing: Space.lg) {
                Button("Log in") {
                    Task { await remote.login(email: email, password: password); password = "" }
                }
                .buttonStyle(SecondaryPillStyle())

                if !showConfig {
                    Button("Edit connection") { showConfig = true }
                        .buttonStyle(GhostTextStyle(color: Ink.mute))
                }
            }

            HStack(spacing: Space.xs) {
                Text("No account yet?")
                    .font(Type.captionMD)
                    .foregroundStyle(Ink.mute)
                Link("Sign up at force.clupai.com ↗", destination: SyncSection.signupURL)
                    .font(Type.captionMD)
                    .foregroundStyle(Ink.ink)
                Spacer(minLength: 0)
            }
            .padding(.top, Space.xxs)
        }
        .padding(Space.lg)
        .background(Ink.containerLow, in: RoundedRectangle(cornerRadius: Radius.lg))
    }

    @ViewBuilder private var loggedIn: some View {
        VStack(alignment: .leading, spacing: Space.md) {
            Text("Signed in as \(remote.email ?? "—")")
                .font(Type.bodyStrong)
                .foregroundStyle(Ink.ink)
            Text(remote.localDirty
                 ? "You have local edits not yet synced. They'll push on Sync now or when you close Settings."
                 : "Your contract and goals sync both ways. Quotes and reflection are edited on the web.")
                .font(Type.captionMD)
                .foregroundStyle(Ink.mute)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: Space.lg) {
                Button("Sync now") { Task { await remote.syncNow() } }
                    .buttonStyle(SecondaryPillStyle())
                Button("Log out") { remote.logout() }
                    .buttonStyle(GhostTextStyle(color: Ink.mute))
                if !showConfig {
                    Button("Edit connection") { showConfig = true }
                        .buttonStyle(GhostTextStyle(color: Ink.mute))
                }
            }
        }
        .padding(Space.lg)
        .background(Ink.containerLow, in: RoundedRectangle(cornerRadius: Radius.lg))
    }

    @ViewBuilder private var statusLine: some View {
        switch remote.status {
        case .syncing:
            Text("Syncing…").font(Type.captionMD).foregroundStyle(Ink.mute)
        case .synced(let date):
            if date == .distantPast {
                EmptyView()
            } else {
                Text("Last synced \(date.formatted(date: .omitted, time: .shortened))")
                    .font(Type.captionMD).foregroundStyle(Ink.mute)
            }
        case .error(let msg):
            Text(msg).font(Type.captionMD).foregroundStyle(Ink.ink)
        case .needsConfig, .loggedOut:
            EmptyView()
        }
    }

    private func field(_ label: String, text: Binding<String>, placeholder: String) -> some View {
        TextField(placeholder, text: text)
            .textFieldStyle(.plain)
            .font(Type.bodyMD)
            .foregroundStyle(Ink.ink)
            .padding(.horizontal, Space.md)
            .frame(height: 44)
            .background(Ink.bright, in: RoundedRectangle(cornerRadius: Radius.md))
            .accessibilityLabel(label)
    }

    private func secureField(_ label: String, text: Binding<String>) -> some View {
        SecureField(label, text: text)
            .textFieldStyle(.plain)
            .font(Type.bodyMD)
            .foregroundStyle(Ink.ink)
            .padding(.horizontal, Space.md)
            .frame(height: 44)
            .background(Ink.bright, in: RoundedRectangle(cornerRadius: Radius.md))
            .accessibilityLabel(label)
    }
}

// MARK: - Emergency stop

/// Hard kill switch. Disables auto-launch and quits Force immediately,
/// bypassing the acknowledgement close-gate. For when you need out, now.
struct EmergencyStopSection: View {
    @EnvironmentObject var settings: SettingsStore
    @State private var confirming = false

    var body: some View {
        VStack(alignment: .leading, spacing: Space.lg) {
            SectionHeader(kicker: "06 — EMERGENCY", title: "Stop Force")

            Text("Turns off auto-launch and quits immediately, even before today's acknowledgement. Force will not reopen until you launch it again.")
                .font(Type.captionMD)
                .foregroundStyle(Ink.mute)
                .fixedSize(horizontal: false, vertical: true)

            Button("Stop Force now") { confirming = true }
                .buttonStyle(DangerPillStyle())
        }
        .confirmationDialog(
            "Stop Force and disable auto-launch?",
            isPresented: $confirming,
            titleVisibility: .visible
        ) {
            Button("Stop Force", role: .destructive) { stop() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This quits the app right now and removes the LaunchAgent so it won't reopen on schedule or login.")
        }
    }

    private func stop() {
        settings.autoLaunch = false   // didSet uninstalls the LaunchAgent
        LaunchAgent.uninstall()       // belt-and-braces in case it was off but installed
        ExitAuthorizer.shared.exit()  // terminate, bypassing the close-gate
    }
}

// MARK: - Small controls

struct SegmentChip: View {
    let label: String
    let selected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(Type.buttonSM)
                .foregroundStyle(selected ? Ink.onPrimary : Ink.ink)
                .padding(.horizontal, Space.lg)
                .frame(height: 40)
                .background {
                    RoundedRectangle(cornerRadius: Radius.sm)
                        .fill(selected ? AnyShapeStyle(Ink.primaryGradient) : AnyShapeStyle(Ink.containerHigh))
                }
                .scaleEffect(selected ? 1.02 : 1)
                .animation(.spring(response: 0.28, dampingFraction: 0.65), value: selected)
        }
        .buttonStyle(.plain)
    }
}

struct RadioRow: View {
    let title: String
    let detail: String
    let selected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: Space.md) {
                ZStack {
                    Circle().stroke(selected ? Ink.ink : Ink.outline, lineWidth: 1.5)
                    if selected {
                        Circle()
                            .fill(Ink.primaryGradient)
                            .padding(5)
                            .transition(.scale(scale: 0.3).combined(with: .opacity))
                    }
                }
                .frame(width: 20, height: 20)
                .padding(.top, 2)
                .animation(.spring(response: 0.28, dampingFraction: 0.6), value: selected)

                VStack(alignment: .leading, spacing: Space.xxs) {
                    Text(title)
                        .font(Type.bodyStrong)
                        .foregroundStyle(Ink.ink)
                    Text(detail)
                        .font(Type.captionMD)
                        .foregroundStyle(Ink.mute)
                }
                Spacer(minLength: 0)
            }
            .padding(Space.md)
            .background(selected ? Ink.bright : .clear, in: RoundedRectangle(cornerRadius: Radius.md))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.18), value: selected)
    }
}
