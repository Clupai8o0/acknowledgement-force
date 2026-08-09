import DefaultBackend
import SwiftCrossUI
import ForceKit

/// `force-desktop` — the native GUI for Windows and Linux (and macOS, for
/// verification). Renders via SwiftCrossUI's default backend: WinUI on Windows,
/// GTK4 on Linux, AppKit on macOS.
///
/// The model is held in `@State` here so the App observes its `@Published`
/// changes; `.environment(model)` shares the same instance with every child
/// view (`@Environment(DesktopModel.self)`).
@main
struct ForceDesktopApp: App {
    @State var model = DesktopModel()

    var body: some Scene {
        WindowGroup("Acknowledgement Force") {
            ContentView()
                .environment(model)
                .task { await model.launchSync() }
        }
        .defaultSize(width: 1100, height: 760)
    }
}

/// Routes between onboarding, the locked contract, and the dashboard — the
/// desktop equivalent of the macOS `RootView`.
struct ContentView: View {
    @Environment(DesktopModel.self) var model

    var body: some View {
        Group {
            if !model.hasOnboarded {
                OnboardingView()
            } else if model.gateOpen {
                DashboardView()
            } else {
                ContractView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Ink.base)
        .onAppear { model.recomputeGate() }
    }
}

/// Minimal first-run setup: capture the display name and re-lock schedule.
struct OnboardingView: View {
    @Environment(DesktopModel.self) var model
    @State var name = ""
    @State var frequency = Frequency.daily

    var body: some View {
        VStack(spacing: Space.xl) {
            VStack(spacing: Space.sm) {
                Text("ACKNOWLEDGEMENT FORCE")
                    .font(Type.display(34))
                    .foregroundColor(Ink.ink)
                Text("Set up your daily contract.")
                    .font(Type.bodyMD)
                    .foregroundColor(Ink.mute)
            }

            VStack(alignment: .leading, spacing: Space.sm) {
                Text("YOUR NAME")
                    .font(Type.captionSM)
                    .foregroundColor(Ink.mute)
                TextField("Your name", text: $name)
                    .padding(Space.md)
                    .background(Ink.containerHigh)
                    .cornerRadius(Radius.md)
                    .frame(maxWidth: 420)
            }

            VStack(alignment: .leading, spacing: Space.sm) {
                Text("RE-LOCK SCHEDULE")
                    .font(Type.captionSM)
                    .foregroundColor(Ink.mute)
                VStack(spacing: Space.xs) {
                    ForEach(Frequency.allCases, id: \.id) { freq in
                        FrequencyRow(
                            frequency: freq,
                            selected: freq == frequency,
                            action: { frequency = freq }
                        )
                    }
                }
                .frame(maxWidth: 420)
            }

            PrimaryButton(title: "Begin") {
                model.setDisplayName(name)
                model.setFrequency(frequency)
                model.completeOnboarding()
            }
        }
        .padding(Space.section)
        .frame(maxWidth: 560)
        .onAppear { name = model.displayName }
    }
}

/// A selectable schedule row used in onboarding and settings.
struct FrequencyRow: View {
    let frequency: Frequency
    let selected: Bool
    let action: () -> Void

    var body: some View {
        HStack(spacing: Space.md) {
            Text(selected ? "●" : "○").foregroundColor(selected ? Ink.ink : Ink.mute)
            VStack(alignment: .leading, spacing: Space.xxs) {
                Text(frequency.label).font(Type.bodyStrong).foregroundColor(Ink.ink)
                Text(frequency.detail).font(Type.captionMD).foregroundColor(Ink.mute)
            }
            Spacer()
        }
        .padding(Space.md)
        .frame(maxWidth: .infinity)
        .background(selected ? Ink.containerHigh : Ink.containerLow)
        .cornerRadius(Radius.md)
        .onTapGesture { action() }
    }
}
