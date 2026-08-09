import SwiftUI

// A meditative full-canvas presentation of today's single action.
// Nothing else — just the words, on a quiet field, with a faint
// breathing halo. Escape, click, or the corner "Done" exits.

struct FocusModeView: View {
    @Binding var isPresented: Bool
    let action: String
    let displayName: String

    @State private var appeared = false
    @State private var breathe = false
    @State private var textBlur: CGFloat = 12

    var body: some View {
        ZStack {
            Ink.base.ignoresSafeArea()

            // Soft radial wash so the canvas reads as paper, not a slab.
            RadialGradient(
                colors: [Ink.containerLow.opacity(0.85), Ink.base, Ink.base],
                center: .center,
                startRadius: 80,
                endRadius: 720
            )
            .ignoresSafeArea()
            .opacity(appeared ? 1 : 0)
            .scaleEffect(breathe ? 1.04 : 0.98)
            .animation(.easeInOut(duration: 5).repeatForever(autoreverses: true), value: breathe)
            .animation(.easeOut(duration: 1.0), value: appeared)

            VStack(spacing: Space.xxl) {
                Spacer(minLength: 0)

                // Tiny editorial kicker.
                VStack(spacing: Space.sm) {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Ink.ink.opacity(0.7))
                        .frame(width: 32, height: 1.5)
                    Text("TODAY'S ONE THING")
                        .font(Type.captionSM)
                        .tracking(2.0)
                        .foregroundStyle(Ink.mute)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : -8)
                .animation(.easeOut(duration: 0.7).delay(0.15), value: appeared)

                // The words.
                Text(action.isEmpty ? "—" : action)
                    .font(Type.display(actionFontSize))
                    .tracking(-0.6)
                    .foregroundStyle(Ink.ink)
                    .multilineTextAlignment(.center)
                    .lineSpacing(8)
                    .frame(maxWidth: 820)
                    .padding(.horizontal, Space.section)
                    .opacity(appeared ? 1 : 0)
                    .blur(radius: textBlur)
                    .scaleEffect(appeared ? 1 : 0.985)
                    .animation(.easeOut(duration: 1.1).delay(0.28), value: appeared)

                // Whispered name signature, if the user has one.
                if !displayName.isEmpty {
                    Text("— \(displayName.uppercased())")
                        .font(Type.captionSM)
                        .tracking(1.6)
                        .foregroundStyle(Ink.mute)
                        .opacity(appeared ? 0.8 : 0)
                        .animation(.easeOut(duration: 0.8).delay(0.55), value: appeared)
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Quiet exit affordances at the corners.
            VStack {
                HStack {
                    Text("FOCUS")
                        .font(Type.captionSM)
                        .tracking(1.4)
                        .foregroundStyle(Ink.mute.opacity(0.6))
                    Spacer()
                    Button("Done") { close() }
                        .buttonStyle(GhostTextStyle(color: Ink.mute))
                        .keyboardShortcut(.escape, modifiers: [])
                }
                .padding(Space.section)
                Spacer()
                HStack {
                    Spacer()
                    Text("ESC TO EXIT")
                        .font(Type.utilityXS)
                        .tracking(2.0)
                        .foregroundStyle(Ink.mute.opacity(0.4))
                    Spacer()
                }
                .padding(.bottom, Space.xl)
            }
        }
        .contentShape(Rectangle())
        // Single-click anywhere outside the words to exit, like dismissing a card.
        .background(
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture(count: 2) { close() }
        )
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) { appeared = true }
            withAnimation(.easeOut(duration: 1.0).delay(0.28)) { textBlur = 0 }
            breathe = true
        }
    }

    private var actionFontSize: CGFloat {
        let len = action.count
        switch len {
        case 0..<40:   return 64
        case 40..<90:  return 52
        case 90..<160: return 42
        default:       return 34
        }
    }

    private func close() {
        withAnimation(.easeOut(duration: 0.35)) {
            appeared = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
            isPresented = false
        }
    }
}
