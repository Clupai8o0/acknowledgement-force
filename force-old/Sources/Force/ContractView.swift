import SwiftUI
import ForceKit

struct ContractView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var settings: SettingsStore

    @State private var scrolledToBottom = false
    @State private var scrollUnlocked = false
    @State private var unlockWorkItem: DispatchWorkItem?

    @State private var acknowledged = false
    @State private var actionText = ""
    @State private var bodyAppeared = false
    @FocusState private var actionFocused: Bool

    private let bottomSentinel = "contract-bottom"

    private var canConfirm: Bool {
        scrollUnlocked && acknowledged && !actionText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var statusMessage: String {
        if !scrollUnlocked { return "Scroll to the bottom of the contract." }
        if !acknowledged { return "Check the acknowledgement box." }
        if actionText.trimmingCharacters(in: .whitespaces).isEmpty { return "Enter your highest-leverage action for today." }
        return "Ready to confirm."
    }

    var body: some View {
        VStack(spacing: 0) {
            contractScroll
            form
        }
        .background(Ink.base)
    }

    // MARK: Header — campaign lockup (scrolls with the contract body)
    private var header: some View {
        VStack(alignment: .leading, spacing: Space.md) {
            Text("DAILY CONTRACT")
                .font(Type.captionSM)
                .tracking(1.5)
                .foregroundStyle(Ink.mute)
            RoundedRectangle(cornerRadius: 1).fill(Ink.ink).frame(width: 40, height: 2)
            Text("ACKNOWLEDGEMENT\nFORCE")
                .font(Type.display(44))
                .tracking(-0.9)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .foregroundStyle(Ink.ink)
            Text("Read carefully. Acknowledge intentionally.")
                .font(Type.bodyMD)
                .foregroundStyle(Ink.mute)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, Space.xl)
    }

    // MARK: Contract body
    private var contractScroll: some View {
        ScrollViewReader { _ in
            ScrollView {
                VStack(alignment: .leading, spacing: Space.lg) {
                    header
                    ForEach(Array(Contract.blocks(from: settings.contractText, date: AppDate.longToday(), name: settings.displayName).enumerated()), id: \.offset) { _, block in
                        blockView(block)
                    }
                    // Bottom sentinel detects scroll completion.
                    Color.clear
                        .frame(height: 1)
                        .id(bottomSentinel)
                        .background(
                            GeometryReader { geo -> Color in
                                let frame = geo.frame(in: .named("contractScroll"))
                                DispatchQueue.main.async { onSentinel(frame: frame) }
                                return Color.clear
                            }
                        )
                }
                .frame(maxWidth: 760, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, Space.section)
                .padding(.vertical, Space.xl)
                .opacity(bodyAppeared ? 1 : 0)
                .blur(radius: bodyAppeared ? 0 : 12)
                .scaleEffect(bodyAppeared ? 1 : 1.03, anchor: .top)
            }
            .coordinateSpace(name: "contractScroll")
            .background(Ink.base)
            .onAppear {
                withAnimation(.easeOut(duration: 0.85).delay(0.15)) { bodyAppeared = true }
            }
        }
    }

    private func onSentinel(frame: CGRect) {
        // Sentinel visible within the viewport height ⇒ at bottom.
        let atBottom = frame.minY < 900
        if atBottom && !scrolledToBottom {
            scrolledToBottom = true
            scheduleUnlock()
        }
    }

    private func scheduleUnlock() {
        guard !scrollUnlocked, unlockWorkItem == nil else { return }
        let work = DispatchWorkItem {
            withAnimation(.easeOut(duration: 0.3)) { scrollUnlocked = true }
            unlockWorkItem = nil
        }
        unlockWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: work)
    }

    // MARK: Block rendering
    @ViewBuilder
    private func blockView(_ block: ContractBlock) -> some View {
        switch block {
        case .h1(let s):
            Text(s.uppercased())
                .font(Type.headingXL)
                .foregroundStyle(Ink.ink)
                .padding(.top, Space.sm)
        case .h2(let s):
            Text(s.uppercased())
                .font(Type.headingLG)
                .foregroundStyle(Ink.ink)
                .padding(.top, Space.md)
        case .h3(let s):
            Text(s).font(Type.headingMD).foregroundStyle(Ink.ink)
        case .rule:
            Hairline(color: Ink.hairline).padding(.vertical, Space.xs)
        case .paragraph(let runs):
            inlineText(runs).lineSpacing(5)
        case .numbered(let n, let runs):
            HStack(alignment: .top, spacing: Space.md) {
                Text("\(n).").font(Type.bodyStrong).foregroundStyle(Ink.ink).frame(width: 24, alignment: .leading)
                inlineText(runs).lineSpacing(4)
            }
        case .bullet(let runs):
            HStack(alignment: .top, spacing: Space.md) {
                Circle().fill(Ink.ink).frame(width: 5, height: 5).padding(.top, 8)
                inlineText(runs).lineSpacing(4)
            }
        case .checkbox(let runs):
            HStack(alignment: .top, spacing: Space.md) {
                RoundedRectangle(cornerRadius: 3)
                    .stroke(Ink.outline, lineWidth: 1.5)
                    .frame(width: 16, height: 16)
                    .padding(.top, 3)
                inlineText(runs).lineSpacing(4)
            }
        case .blockquote(let runs):
            HStack(alignment: .top, spacing: Space.md) {
                RoundedRectangle(cornerRadius: 1)
                    .fill(Ink.hairline)
                    .frame(width: 3)
                inlineText(runs, color: Ink.mute).lineSpacing(5)
            }
        }
    }

    // MARK: Acknowledgement form
    private var form: some View {
        VStack(alignment: .leading, spacing: Space.lg) {
            Button { acknowledged.toggle() } label: {
                HStack(spacing: Space.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: Radius.xs)
                            .fill(acknowledged ? AnyShapeStyle(Ink.primaryGradient) : AnyShapeStyle(Ink.bright))
                        if !acknowledged {
                            RoundedRectangle(cornerRadius: Radius.xs)
                                .stroke(Ink.outline, lineWidth: 1.5)
                        }
                        if acknowledged {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Ink.onPrimary)
                                .transition(.scale(scale: 0.4).combined(with: .opacity))
                        }
                    }
                    .frame(width: 22, height: 22)
                    .scaleEffect(acknowledged ? 1.08 : 1)
                    .animation(.spring(response: 0.3, dampingFraction: 0.55), value: acknowledged)

                    Text("I have read and acknowledge this contract for today")
                        .font(Type.bodyStrong)
                        .foregroundStyle(scrollUnlocked ? Ink.ink : Ink.stone)
                }
            }
            .buttonStyle(.plain)
            .disabled(!scrollUnlocked)

            VStack(alignment: .leading, spacing: Space.sm) {
                Text("TODAY'S SINGLE HIGHEST-LEVERAGE ACTION")
                    .font(Type.captionSM)
                    .tracking(1.0)
                    .foregroundStyle(Ink.mute)
                TextField("What is the ONE thing you must do today?", text: $actionText)
                    .textFieldStyle(.plain)
                    .font(Type.bodyMD)
                    .foregroundStyle(Ink.ink)
                    .focused($actionFocused)
                    .padding(.horizontal, Space.lg)
                    .frame(height: 52)
                    .filledField(focused: actionFocused, enabled: scrollUnlocked)
                    .disabled(!scrollUnlocked)
            }

            HStack(spacing: Space.xl) {
                Button("Confirm & Continue") {
                    store.confirm(action: actionText.trimmingCharacters(in: .whitespaces))
                }
                .buttonStyle(PrimaryPillStyle(enabled: canConfirm))
                .disabled(!canConfirm)

                Text(statusMessage)
                    .font(Type.captionMD)
                    .foregroundStyle(Ink.mute)
            }
        }
        .frame(maxWidth: 760)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal, Space.section)
        .padding(.vertical, Space.xl)
        .background(Ink.containerLow)
        .opacity(bodyAppeared ? 1 : 0)
        .offset(y: bodyAppeared ? 0 : 16)
        .animation(.spring(response: 0.6, dampingFraction: 0.85).delay(0.3), value: bodyAppeared)
    }
}
