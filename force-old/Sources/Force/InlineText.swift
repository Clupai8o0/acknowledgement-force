import SwiftUI
import ForceKit

// Renders [Inline] runs into a single Text with bold segments.
func inlineText(_ runs: [Inline], base: Font = Type.bodyMD, color: Color = Ink.charcoal) -> Text {
    runs.reduce(Text("")) { acc, run in
        switch run {
        case .plain(let s):
            return acc + Text(s).font(base).foregroundColor(color)
        case .bold(let s):
            return acc + Text(s).font(base.weight(.semibold)).foregroundColor(Ink.ink)
        }
    }
}
