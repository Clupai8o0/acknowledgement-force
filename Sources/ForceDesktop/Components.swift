import SwiftCrossUI

// SwiftCrossUI 0.7's `Button` only accepts a plain `String` label, so any
// styled or custom-content control is built as a tappable styled view via
// `.onTapGesture`. These mirror the macOS button styles (ink pill / ghost).

/// Filled "ink" pill — the primary action (Confirm, Begin, Sign in).
struct PrimaryButton: View {
    let title: String
    var enabled: Bool = true
    let action: () -> Void

    var body: some View {
        Text(title)
            .font(Type.buttonMD)
            .foregroundColor(Ink.onPrimary)
            .padding(.horizontal, Space.xl)
            .padding(.vertical, Space.md)
            .background(enabled ? Ink.ink : Ink.stone)
            .cornerRadius(Radius.sm)
            .onTapGesture { if enabled { action() } }
    }
}

/// Text-only ghost button — secondary/tertiary actions.
struct GhostButton: View {
    let title: String
    var color: Color = Ink.mute
    let action: () -> Void

    var body: some View {
        Text(title)
            .font(Type.buttonMD)
            .foregroundColor(color)
            .padding(.horizontal, Space.md)
            .padding(.vertical, Space.sm)
            .onTapGesture { action() }
    }
}

extension View {
    /// Filled input/field treatment on `surface-container-high`.
    func fieldBox() -> some View {
        self.padding(Space.md)
            .background(Ink.containerHigh)
            .cornerRadius(Radius.md)
    }

    /// Tonal card surface.
    func card() -> some View {
        self.padding(Space.xl)
            .background(Ink.bright)
            .cornerRadius(Radius.lg)
    }
}
