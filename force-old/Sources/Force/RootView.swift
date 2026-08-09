import SwiftUI

struct RootView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var remote: RemoteSync
    @Environment(\.colorScheme) private var colorScheme
    @State private var introDone = false

    // The intro plays only for an onboarded user; until it finishes the main
    // content stays unmounted so it can dissolve in as the rings collapse.
    private var needsIntro: Bool { settings.hasOnboarded && !introDone }

    var body: some View {
        ZStack {
            Ink.base.ignoresSafeArea()

            if !needsIntro {
                Group {
                    if !settings.hasOnboarded {
                        OnboardingView()
                    } else if store.gateOpen {
                        AppView()
                    } else {
                        ContractView()
                    }
                }
                .transition(.editorial)
            }

            if needsIntro {
                IntroView(
                    displayName: settings.displayName,
                    onFinish: { withAnimation(.easeOut(duration: 0.7)) { introDone = true } }
                )
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.6), value: store.gateOpen)
        .animation(.easeInOut(duration: 0.6), value: settings.hasOnboarded)
        .animation(.easeInOut(duration: 0.7), value: introDone)
        .onChange(of: colorScheme) { _, _ in theme.refreshSystem() }
        .task { await remote.launchSync() }
    }
}

// MARK: - Intro
// Soft radial glow + breathing concentric rings + blur-in text. ~3.2s, then fades.

struct IntroView: View {
    let displayName: String
    let onFinish: () -> Void
    @State private var appeared = false
    @State private var breathe = false
    @State private var collapsing = false
    @State private var textBlur: CGFloat = 14

    /// Greets by display name when one is set; plain otherwise.
    private var welcomeLine: String {
        let name = displayName.trimmingCharacters(in: .whitespaces)
        return name.isEmpty
            ? "Welcome. Take a deep breath."
            : "Welcome, \(name). Take a deep breath."
    }

    // Rings rush back inward (the reverse of their spread-out entrance),
    // converging toward the title before the contract dissolves in.
    private var ringCollapse: CGFloat { collapsing ? 0.04 : 1 }
    private var collapseAnim: Animation { .easeIn(duration: 0.62) }

    var body: some View {
        ZStack {
            Ink.base.ignoresSafeArea()

            // Light-opacity radial wash — warms the canvas behind the rings
            RadialGradient(
                colors: [
                    Ink.success.opacity(0.10),
                    Ink.success.opacity(0.04),
                    .clear
                ],
                center: .center,
                startRadius: 0,
                endRadius: 460
            )
            .ignoresSafeArea()
            .opacity(appeared ? 1 : 0)
            .scaleEffect(breathe ? 1.06 : 0.96)
            .scaleEffect(ringCollapse)
            .opacity(collapsing ? 0 : 1)
            .animation(.easeOut(duration: 2.0), value: appeared)
            .animation(.easeInOut(duration: 3.4).repeatForever(autoreverses: true), value: breathe)
            .animation(collapseAnim, value: collapsing)

            // Outer ring — slowest, most subtle
            Circle()
                .stroke(Ink.ink.opacity(0.05), lineWidth: 0.5)
                .frame(width: 620, height: 620)
                .scaleEffect(appeared ? (breathe ? 1.015 : 1) : 0.08)
                .scaleEffect(ringCollapse)
                .opacity(collapsing ? 0 : (appeared ? 1 : 0))
                .animation(.easeOut(duration: 3.2), value: appeared)
                .animation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true), value: breathe)
                .animation(collapseAnim, value: collapsing)

            // Middle ring
            Circle()
                .stroke(Ink.ink.opacity(0.10), lineWidth: 0.75)
                .frame(width: 420, height: 420)
                .scaleEffect(appeared ? (breathe ? 1.02 : 1) : 0.08)
                .scaleEffect(ringCollapse)
                .opacity(collapsing ? 0 : (appeared ? 1 : 0))
                .animation(.easeOut(duration: 2.5).delay(0.1), value: appeared)
                .animation(.easeInOut(duration: 3.4).repeatForever(autoreverses: true), value: breathe)
                .animation(collapseAnim.delay(0.04), value: collapsing)

            // Soft halo behind the inner ring
            Circle()
                .fill(Ink.success.opacity(0.06))
                .frame(width: 230, height: 230)
                .blur(radius: 30)
                .scaleEffect(appeared ? (breathe ? 1.08 : 0.94) : 0.08)
                .scaleEffect(ringCollapse)
                .opacity(collapsing ? 0 : (appeared ? 1 : 0))
                .animation(.easeOut(duration: 1.8).delay(0.2), value: appeared)
                .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: breathe)
                .animation(collapseAnim.delay(0.08), value: collapsing)

            // Inner ring — gradient stroke for a chromatic accent
            Circle()
                .strokeBorder(
                    AngularGradient(
                        colors: [Ink.success.opacity(0.5), Ink.ink.opacity(0.18), .clear, Ink.success.opacity(0.28), Ink.success.opacity(0.5)],
                        center: .center
                    ),
                    lineWidth: 1.25
                )
                .frame(width: 230, height: 230)
                .scaleEffect(appeared ? (breathe ? 1.03 : 1) : 0.08)
                .scaleEffect(ringCollapse)
                .opacity(collapsing ? 0 : (appeared ? 1 : 0))
                .animation(.easeOut(duration: 1.8).delay(0.2), value: appeared)
                .animation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true), value: breathe)
                .animation(collapseAnim.delay(0.1), value: collapsing)

            VStack(spacing: Space.lg) {
                Text("ACKNOWLEDGEMENT")
                    .font(Type.display(58))
                    .tracking(-0.5)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                    .foregroundStyle(Ink.ink)
                Text("FORCE")
                    .font(Type.display(58))
                    .tracking(-0.5)
                    .foregroundStyle(Ink.ink)
                Text(welcomeLine)
                    .font(Type.bodyMD)
                    .foregroundStyle(Ink.mute)
                    .padding(.top, Space.sm)
            }
            .multilineTextAlignment(.center)
            .opacity(appeared ? (collapsing ? 0 : 1) : 0)
            .blur(radius: collapsing ? 10 : textBlur)
            .scaleEffect(appeared ? (collapsing ? 1.06 : 1) : 0.96)
            .animation(.easeOut(duration: 1.1).delay(0.28), value: appeared)
            .animation(.easeIn(duration: 0.5), value: collapsing)
        }
        .onAppear {
            withAnimation { appeared = true }
            withAnimation(.easeOut(duration: 1.1).delay(0.28)) { textBlur = 0 }
            breathe = true
            // Breathe, then pull the rings back inward and dissolve into the app.
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(collapseAnim) { collapsing = true }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.1) { onFinish() }
        }
    }
}
