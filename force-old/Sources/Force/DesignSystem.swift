import SwiftUI

// MARK: - Color tokens
// "The Digital Curator" — a monochrome surface system. Depth comes from
// stacking tonal layers, never from 1px borders.

enum Ink {
    private static var t: Theme { ThemeManager.current }

    // Surface tiers (lowest pops on top of low/base).
    static var base: Color             { Color(rgb: t.base) }
    static var containerLow: Color     { Color(rgb: t.containerLow) }
    static var container: Color        { Color(rgb: t.container) }
    static var containerHigh: Color    { Color(rgb: t.containerHigh) }
    static var containerHighest: Color { Color(rgb: t.containerHighest) }
    static var bright: Color           { Color(rgb: t.bright) }

    // Ink.
    static var ink: Color          { Color(rgb: t.ink) }
    static var inkContainer: Color { Color(rgb: t.inkContainer) }
    static var ash: Color          { Color(rgb: t.ash) }
    static var mute: Color         { Color(rgb: t.mute) }            // on-surface-variant
    static var onSurfaceVariant: Color { Color(rgb: t.mute) }
    static var stone: Color        { Color(rgb: t.stone) }
    static var outline: Color      { Color(rgb: t.outline) }
    static var outlineSoft: Color  { Color(rgb: t.outlineSoft) }
    static var onPrimary: Color    { Color(rgb: t.onPrimary) }

    // Legacy aliases retained so older call-sites keep resolving.
    static var canvas: Color       { Color(rgb: t.containerLow) }
    static var softCloud: Color    { Color(rgb: t.containerHigh) }
    static var charcoal: Color     { Color(rgb: t.inkContainer) }
    static var hairline: Color     { Color(rgb: t.outline) }
    static var hairlineSoft: Color { Color(rgb: t.outlineSoft) }
    static var success: Color { Color(rgb: t.ink) }
    static var sale: Color    { Color(rgb: t.ink) }
    static var info: Color    { Color(rgb: t.ink) }

    /// Monochrome "primary" gradient (135°) used for filled emphasis.
    static var primaryGradient: LinearGradient {
        LinearGradient(colors: [ink, inkContainer], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - Elevation
// No material drop-shadows. A single ultra-diffused "ghost shadow" tinted with
// on-surface, plus a glass treatment for floating overlays.

extension View {
    /// 0px 24px 48px rgba(26,28,28,0.06) — the only sanctioned shadow.
    func ambientShadow() -> some View {
        shadow(color: Ink.ink.opacity(0.06), radius: 24, x: 0, y: 16)
    }

    /// Semi-transparent surface + backdrop blur for floating navigation/overlays.
    func glass(_ radius: CGFloat = Radius.lg) -> some View {
        background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: radius))
            .background(Ink.base.opacity(0.55), in: RoundedRectangle(cornerRadius: radius))
    }

    /// Soft monochrome emphasis (replaces colored glows).
    func glow(color: Color, radius: CGFloat = 8) -> some View {
        shadow(color: color.opacity(0.18), radius: radius)
    }
}

// MARK: - Transitions
// A shared vocabulary so screens and elements enter/leave the same way the
// intro dissolves: softening (blur), settling (scale), fading (opacity).

private struct BlurModifier: ViewModifier {
    let radius: CGFloat
    func body(content: Content) -> some View { content.blur(radius: radius) }
}

extension AnyTransition {
    /// Soft focus pull — pairs with the intro's ring collapse.
    static var blurFocus: AnyTransition {
        .modifier(active: BlurModifier(radius: 14), identity: BlurModifier(radius: 0))
    }

    /// Editorial screen swap: fade + gentle scale + soft focus.
    static var editorial: AnyTransition {
        .opacity
            .combined(with: .scale(scale: 1.04))
            .combined(with: blurFocus)
    }

    /// Horizontal step transition that respects travel direction.
    static func directional(forward: Bool) -> AnyTransition {
        .asymmetric(
            insertion: .opacity.combined(with: .offset(x: forward ? 28 : -28)),
            removal: .opacity.combined(with: .offset(x: forward ? -28 : 28))
        )
    }
}

// MARK: - Radius scale (editorial, not pill)
enum Radius {
    static let none: CGFloat = 0
    static let xs: CGFloat   = 4
    static let sm: CGFloat   = 6   // buttons — spec "md" 0.375rem
    static let md: CGFloat   = 8   // inputs
    static let lg: CGFloat   = 14  // cards / surfaces
    static let xl: CGFloat   = 20
    static let full: CGFloat = 9999
}

// MARK: - Spacing — generous, room to breathe
enum Space {
    static let xxs: CGFloat     = 2
    static let xs: CGFloat      = 4
    static let sm: CGFloat      = 8
    static let md: CGFloat      = 12
    static let lg: CGFloat      = 20
    static let xl: CGFloat      = 28
    static let xxl: CGFloat     = 40
    static let section: CGFloat = 56
}

// MARK: - Typography — the academic dialogue
// Fraunces (editorial serif) for display/headline gravitas; Inter for body & metadata.
enum Type {
    static let displayFont = "Fraunces"
    static let uiFont      = "Inter"

    /// Editorial serif display, Fraunces. Pair with slight negative tracking at call sites.
    static func display(_ size: CGFloat) -> Font {
        .custom(displayFont, size: size).weight(.regular)
    }

    // Headlines & titles — Fraunces serif
    static let headingXL  = Font.custom(displayFont, size: 28).weight(.medium) // headline
    static let headingLG  = Font.custom(displayFont, size: 22).weight(.medium)
    static let headingMD  = Font.custom(displayFont, size: 17).weight(.medium)

    // Body — Inter
    static let bodyMD     = Font.custom(uiFont, size: 16).weight(.regular)   // body-lg
    static let bodyStrong = Font.custom(uiFont, size: 16).weight(.medium)

    static let buttonLG = Font.custom(uiFont, size: 22).weight(.semibold)
    static let buttonMD = Font.custom(uiFont, size: 15).weight(.semibold)
    static let buttonSM = Font.custom(uiFont, size: 13).weight(.medium)

    static let captionMD = Font.custom(uiFont, size: 13).weight(.regular)
    static let captionSM = Font.custom(uiFont, size: 11).weight(.medium) // label-sm (all-caps + tracking)
    static let utilityXS = Font.custom(uiFont, size: 9).weight(.medium)
}

// MARK: - Buttons
// Names retained for compatibility; visual language is now editorial (6px radius,
// gradient fill, no drop shadow).

struct PrimaryPillStyle: ButtonStyle {
    var enabled: Bool = true
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Type.buttonMD)
            .foregroundStyle(Ink.onPrimary)
            .padding(.horizontal, Space.xl)
            .frame(height: 48)
            .background {
                RoundedRectangle(cornerRadius: Radius.sm).fill(
                    enabled ? Ink.primaryGradient
                            : LinearGradient(colors: [Ink.stone, Ink.stone], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            }
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// Ghost style — no background, ink text, subtle container hover.
struct SecondaryPillStyle: ButtonStyle {
    @State private var hovering = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Type.buttonMD)
            .foregroundStyle(Ink.ink)
            .padding(.horizontal, Space.xl)
            .frame(height: 48)
            .background {
                RoundedRectangle(cornerRadius: Radius.sm)
                    .fill(hovering ? Ink.containerHigh : .clear)
            }
            .onHover { hovering = $0 }
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.7 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.6), value: configuration.isPressed)
            .animation(.easeOut(duration: 0.15), value: hovering)
    }
}

/// Destructive — monochrome fill (B&W system); the confirmation dialog carries the warning.
struct DangerPillStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Type.buttonMD)
            .foregroundStyle(Ink.onPrimary)
            .padding(.horizontal, Space.xl)
            .frame(height: 48)
            .background {
                RoundedRectangle(cornerRadius: Radius.sm).fill(Ink.primaryGradient)
            }
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct OnImagePillStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Type.buttonMD)
            .foregroundStyle(Ink.ink)
            .padding(.horizontal, Space.xl)
            .padding(.vertical, Space.md)
            .background(Ink.bright, in: RoundedRectangle(cornerRadius: Radius.sm))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.7 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct GhostTextStyle: ButtonStyle {
    var color: Color = Ink.ink
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Type.buttonSM)
            .foregroundStyle(color)
            .opacity(configuration.isPressed ? 0.4 : 1)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Filled input field (no bottom line; left accent on focus)
extension View {
    /// Filled field on `surface-container-high`; a 3px left accent in `ink`
    /// appears only while focused. No outline.
    func filledField(focused: Bool, enabled: Bool = true) -> some View {
        background {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: Radius.md)
                    .fill(Ink.containerHigh.opacity(enabled ? 1 : 0.5))
                if focused {
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(Ink.ink)
                        .frame(width: 3)
                        .padding(.vertical, 6)
                        .transition(.opacity)
                }
            }
        }
        .animation(.easeOut(duration: 0.18), value: focused)
    }
}

// MARK: - Tonal card (no border; ghost shadow on hover)
struct TonalCard<Content: View>: View {
    var resting: Color = Ink.bright
    var padding: CGFloat = Space.xl
    @ViewBuilder var content: () -> Content
    @State private var hovering = false

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(hovering ? Ink.bright : resting, in: RoundedRectangle(cornerRadius: Radius.lg))
            .modifier(HoverShadow(hovering: hovering))
            .onHover { hovering = $0 }
            .animation(.easeOut(duration: 0.2), value: hovering)
    }
}

private struct HoverShadow: ViewModifier {
    var hovering: Bool
    func body(content: Content) -> some View {
        if hovering { content.ambientShadow() } else { content }
    }
}

// MARK: - Hairline divider
// Retained as a near-invisible "ghost border" (outline at 15% opacity). The
// no-line rule means most call-sites should drop these in favor of tonal shifts.
struct Hairline: View {
    var color: Color = Ink.outline
    var body: some View {
        Rectangle().fill(color.opacity(0.15)).frame(height: 1)
    }
}
