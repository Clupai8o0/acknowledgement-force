import SwiftUI
import ForceKit

struct AppView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var settings: SettingsStore
    @State private var showHistory = false
    @State private var showSettings = false
    @State private var showFocus = false
    @State private var editingAction = false
    @State private var actionDraft = ""
    @FocusState private var actionFieldFocused: Bool
    @State private var headerAppeared = false
    @State private var cardAppeared = false
    @State private var motivationAppeared = false

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            mainContent
        }
        .background(Ink.base)
        .sheet(isPresented: $showHistory) {
            HistoryView(isPresented: $showHistory)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(isPresented: $showSettings)
        }
        .sheet(isPresented: $showFocus) {
            FocusModeView(
                isPresented: $showFocus,
                action: store.todayAction,
                displayName: settings.displayName
            )
            .frame(minWidth: 1100, minHeight: 760)
        }
    }

    // MARK: Sidebar
    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("DAILY NON-\nNEGOTIABLES")
                    .font(Type.headingMD)
                    .foregroundStyle(Ink.ink)
                Spacer()
                progressBadge
            }
            .padding(.bottom, Space.xl)

            VStack(spacing: Space.xs) {
                ForEach(Array(settings.nonNegotiables.enumerated()), id: \.element.id) { idx, item in
                    ChecklistRow(
                        label: item.label,
                        checked: store.checklistState[item.id] ?? false,
                        index: idx,
                        action: { store.toggle(item.id) }
                    )
                }
            }

            Spacer()

            VStack(spacing: Space.sm) {
                Button("View Past Actions") { showHistory = true }
                    .buttonStyle(SecondaryPillStyle())
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(Space.xl)
        .frame(width: 340)
        .background(Ink.containerLow)
    }

    /// Greets by display name when one is set; plain otherwise.
    private var welcomeTitle: String {
        let name = settings.displayName.trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? "WELCOME BACK" : "WELCOME BACK, \(name.uppercased())"
    }

    private func beginEditing() {
        actionDraft = store.todayAction
        editingAction = true
        actionFieldFocused = true
    }

    private func commitAction() {
        store.updateTodayAction(actionDraft)
        editingAction = false
        actionFieldFocused = false
    }

    // MARK: Progress badge — numeric transition + success glow
    private var progressBadge: some View {
        let done = store.completedCount
        let total = store.totalCount
        let complete = done == total
        return HStack(spacing: 3) {
            Text("\(done)")
                .contentTransition(.numericText())
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: done)
            Text("/\(total)")
        }
        .font(Type.captionSM)
        .foregroundStyle(complete ? Ink.onPrimary : Ink.ink)
        .padding(.horizontal, Space.md)
        .frame(height: 30)
        .background {
            RoundedRectangle(cornerRadius: Radius.sm).fill(
                complete ? AnyShapeStyle(Ink.primaryGradient) : AnyShapeStyle(Ink.containerHigh)
            )
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.7), value: complete)
    }

    // MARK: Main content
    private var mainContent: some View {
        VStack(alignment: .leading, spacing: Space.section) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: Space.md) {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Ink.ink)
                        .frame(width: 40, height: 2)
                    Text(welcomeTitle)
                        .font(Type.display(40))
                        .tracking(-0.8)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .foregroundStyle(Ink.ink)
                    Text(AppDate.longToday())
                        .font(Type.captionMD)
                        .foregroundStyle(Ink.mute)
                }
                .opacity(headerAppeared ? 1 : 0)
                .offset(y: headerAppeared ? 0 : -10)
                .onAppear {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.88)) {
                        headerAppeared = true
                    }
                }

                Spacer()
                HStack(spacing: Space.lg) {
                    Button("Settings") { showSettings = true }
                        .buttonStyle(GhostTextStyle(color: Ink.mute))
                    Button("Exit") { ExitAuthorizer.shared.exit() }
                        .buttonStyle(GhostTextStyle(color: Ink.mute))
                }
            }

            // Today's action card
            VStack(alignment: .leading, spacing: Space.md) {
                HStack(spacing: Space.md) {
                    Text("TODAY'S HIGHEST-LEVERAGE ACTION")
                        .font(Type.captionSM)
                        .tracking(1.0)
                        .foregroundStyle(Ink.mute)
                    Spacer()
                    Button {
                        showFocus = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .font(.system(size: 10, weight: .semibold))
                            Text("Focus")
                        }
                    }
                    .buttonStyle(GhostTextStyle(color: Ink.mute))
                    .disabled(store.todayAction.trimmingCharacters(in: .whitespaces).isEmpty)
                    .opacity(store.todayAction.trimmingCharacters(in: .whitespaces).isEmpty ? 0.4 : 1)

                    Button(editingAction ? "Save" : "Edit") {
                        if editingAction { commitAction() } else { beginEditing() }
                    }
                    .buttonStyle(GhostTextStyle(color: Ink.mute))
                }
                if editingAction {
                    TextField("What is the ONE thing you must do today?", text: $actionDraft)
                        .textFieldStyle(.plain)
                        .font(Type.headingLG)
                        .foregroundStyle(Ink.ink)
                        .focused($actionFieldFocused)
                        .onSubmit { commitAction() }
                        .transition(.opacity)
                } else {
                    Text(store.todayAction.isEmpty ? "—" : store.todayAction)
                        .font(Type.headingLG)
                        .foregroundStyle(Ink.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Space.xl)
            .background(Ink.bright, in: RoundedRectangle(cornerRadius: Radius.lg))
            .ambientShadow()
            .opacity(cardAppeared ? 1 : 0)
            .offset(y: cardAppeared ? 0 : 12)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.85).delay(0.1)) {
                    cardAppeared = true
                }
            }

            // Reflection (from the web editor)
            if !settings.reflection.trimmingCharacters(in: .whitespaces).isEmpty {
                VStack(alignment: .leading, spacing: Space.sm) {
                    Text("REFLECTION")
                        .font(Type.captionSM)
                        .tracking(1.0)
                        .foregroundStyle(Ink.mute)
                    Text(settings.reflection)
                        .font(Type.bodyMD)
                        .foregroundStyle(Ink.ash)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Space.xl)
                .background(Ink.containerLow, in: RoundedRectangle(cornerRadius: Radius.lg))
            }

            // Motivation quote + daily contract
            if !settings.motivation.trimmingCharacters(in: .whitespaces).isEmpty {
                VStack(alignment: .leading, spacing: Space.md) {
                    Text("\u{201C}\(settings.motivation)\u{201D}")
                        .font(Type.headingLG)
                        .foregroundStyle(Ink.ash)
                        .fixedSize(horizontal: false, vertical: true)

                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: Space.sm) {
                            ForEach(
                                Array(Contract.blocks(from: settings.contractText, date: AppDate.longToday(), name: settings.displayName).enumerated()),
                                id: \.offset
                            ) { _, block in
                                contractBlockView(block)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(maxHeight: .infinity, alignment: .topLeading)
                .opacity(motivationAppeared ? 1 : 0)
                .offset(y: motivationAppeared ? 0 : 10)
                .onAppear {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.85).delay(0.22)) {
                        motivationAppeared = true
                    }
                }
            } else {
                Spacer()
            }
        }
        .padding(Space.section)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Ink.base)
    }

    @ViewBuilder
    private func contractBlockView(_ block: ContractBlock) -> some View {
        switch block {
        case .h1(let s):
            Text(s.uppercased())
                .font(Type.headingMD)
                .foregroundStyle(Ink.ink)
                .padding(.top, Space.xs)
        case .h2(let s):
            Text(s.uppercased())
                .font(Type.bodyStrong)
                .foregroundStyle(Ink.ink)
                .padding(.top, Space.xs)
        case .h3(let s):
            Text(s)
                .font(Type.bodyStrong)
                .foregroundStyle(Ink.charcoal)
        case .rule:
            Hairline(color: Ink.hairlineSoft).padding(.vertical, Space.xxs)
        case .paragraph(let runs):
            inlineText(runs).lineSpacing(3)
        case .numbered(let n, let runs):
            HStack(alignment: .top, spacing: Space.sm) {
                Text("\(n).").font(Type.bodyMD).foregroundColor(Ink.mute).frame(width: 20, alignment: .leading)
                inlineText(runs).lineSpacing(3)
            }
        case .bullet(let runs):
            HStack(alignment: .top, spacing: Space.sm) {
                Circle().fill(Ink.mute).frame(width: 4, height: 4).padding(.top, 7)
                inlineText(runs).lineSpacing(3)
            }
        case .checkbox(let runs):
            HStack(alignment: .top, spacing: Space.sm) {
                RoundedRectangle(cornerRadius: 2)
                    .stroke(Ink.hairline, lineWidth: 1)
                    .frame(width: 12, height: 12)
                    .padding(.top, 4)
                inlineText(runs).lineSpacing(3)
            }
        case .blockquote(let runs):
            HStack(alignment: .top, spacing: Space.sm) {
                RoundedRectangle(cornerRadius: 1)
                    .fill(Ink.hairline)
                    .frame(width: 2)
                inlineText(runs, color: Ink.mute).lineSpacing(3)
            }
        }
    }
}

// MARK: - Checklist row

struct ChecklistRow: View {
    let label: String
    let checked: Bool
    var index: Int = 0
    let action: () -> Void
    @State private var appeared = false
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: Space.md) {
                ZStack {
                    Circle()
                        .fill(checked ? AnyShapeStyle(Ink.primaryGradient) : AnyShapeStyle(Ink.bright))
                    if !checked {
                        Circle().stroke(Ink.outline, lineWidth: 1.5)
                    }
                    if checked {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Ink.onPrimary)
                            .transition(.scale(scale: 0.4).combined(with: .opacity))
                    }
                }
                .frame(width: 22, height: 22)
                .scaleEffect(checked ? 1.08 : 1)
                .animation(.spring(response: 0.3, dampingFraction: 0.55), value: checked)

                Text(label)
                    .font(Type.captionMD)
                    .foregroundStyle(checked ? Ink.mute : Ink.ink)
                    .strikethrough(checked, color: Ink.mute)
                    .multilineTextAlignment(.leading)
                    .animation(.easeOut(duration: 0.18), value: checked)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, Space.md)
            .padding(.vertical, Space.md)
            .background(hovering ? Ink.bright : .clear, in: RoundedRectangle(cornerRadius: Radius.md))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.15), value: hovering)
        .opacity(appeared ? 1 : 0)
        .offset(x: appeared ? 0 : -8)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.82).delay(Double(index) * 0.055)) {
                appeared = true
            }
        }
    }
}
