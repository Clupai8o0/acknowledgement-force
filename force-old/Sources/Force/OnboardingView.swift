import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var settings: SettingsStore
    @State private var step = 0
    @State private var forward = true

    private let lastStep = 4

    var body: some View {
        VStack(spacing: 0) {
            progressBar
            ScrollView {
                content
                    .frame(maxWidth: 620, alignment: .leading)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, Space.section)
                    .padding(.vertical, Space.section)
                    .id(step)
                    .transition(.directional(forward: forward))
            }
            footer
        }
        .background(Ink.base)
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle().fill(Ink.containerHigh)
                Rectangle()
                    .fill(Ink.primaryGradient)
                    .frame(width: geo.size.width * CGFloat(step + 1) / CGFloat(lastStep + 1))
                    .animation(.spring(response: 0.5, dampingFraction: 0.82), value: step)
            }
        }
        .frame(height: 3)
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case 0: welcome
        case 1: AppearanceSection()
        case 2: ScheduleSection()
        case 3: MessagesSection()
        default: finish
        }
    }

    private func advance() {
        forward = true
        withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) { step += 1 }
    }

    private func retreat() {
        forward = false
        withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) { step -= 1 }
    }

    private var welcome: some View {
        VStack(alignment: .leading, spacing: Space.md) {
            Text("WELCOME TO")
                .font(Type.captionSM)
                .tracking(1.5)
                .foregroundStyle(Ink.mute)
            RoundedRectangle(cornerRadius: 1).fill(Ink.ink).frame(width: 40, height: 2)
            Text("ACKNOWLEDGEMENT\nFORCE")
                .font(Type.display(48))
                .tracking(-1.0)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .foregroundStyle(Ink.ink)
            Text("A daily contract you must read and commit to before your Mac is yours. Let's set it up — appearance, how often it locks in, and the messages that keep you honest.")
                .font(Type.bodyMD)
                .foregroundStyle(Ink.ash)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, Space.sm)
        }
    }

    private var finish: some View {
        VStack(alignment: .leading, spacing: Space.md) {
            Text("ALL SET")
                .font(Type.captionSM)
                .tracking(1.5)
                .foregroundStyle(Ink.mute)
            RoundedRectangle(cornerRadius: 1).fill(Ink.ink).frame(width: 40, height: 2)
            Text("YOU'RE READY.")
                .font(Type.display(48))
                .tracking(-1.0)
                .minimumScaleFactor(0.7)
                .foregroundStyle(Ink.ink)
            Text("You can change appearance, schedule, and messages any time from Settings. Take a deep breath — then sign today's contract.")
                .font(Type.bodyMD)
                .foregroundStyle(Ink.ash)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, Space.sm)
        }
    }

    private var footer: some View {
        HStack {
            if step > 0 {
                Button("Back") { retreat() }
                    .buttonStyle(GhostTextStyle(color: Ink.mute))
            }
            Spacer()
            Text("\(step + 1) / \(lastStep + 1)")
                .font(Type.captionMD)
                .foregroundStyle(Ink.mute)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: step)
            Spacer()
            if step < lastStep {
                Button("Continue") { advance() }
                    .buttonStyle(PrimaryPillStyle())
            } else {
                Button("Get Started") {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                        settings.hasOnboarded = true
                    }
                }
                .buttonStyle(PrimaryPillStyle())
            }
        }
        .padding(.horizontal, Space.section)
        .padding(.vertical, Space.xl)
        .background(Ink.containerLow)
    }
}
