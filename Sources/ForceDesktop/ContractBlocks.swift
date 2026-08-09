import SwiftCrossUI
import ForceKit

// Renders ForceKit's parsed `[ContractBlock]` into SwiftCrossUI views, matching
// the macOS ContractView/AppView block styling as closely as the toolkit allows.
//
// Note: SwiftCrossUI 0.7 `Text` has no inline rich-text run support, so inline
// `**bold**` runs are flattened to plain text (the bold marker is dropped).
// Block-level structure, headings, lists, and blockquotes are preserved.

/// Flattens inline runs to a single string (bold styling is not preserved inline).
func inlineString(_ runs: [Inline]) -> String {
    runs.map { run in
        switch run {
        case .plain(let s): return s
        case .bold(let s): return s
        }
    }.joined()
}

/// One contract block as a view. Returns `AnyView` so the per-case branches can
/// differ in concrete type.
@MainActor
func contractBlockView(_ block: ContractBlock) -> AnyView {
    switch block {
    case .h1(let s):
        return AnyView(
            Text(s.uppercased()).font(Type.headingXL).foregroundColor(Ink.ink)
        )
    case .h2(let s):
        return AnyView(
            Text(s.uppercased()).font(Type.headingLG).foregroundColor(Ink.ink)
        )
    case .h3(let s):
        return AnyView(
            Text(s).font(Type.headingMD).foregroundColor(Ink.ink)
        )
    case .rule:
        return AnyView(Divider(Ink.outline.opacity(0.4)))
    case .paragraph(let runs):
        return AnyView(
            Text(inlineString(runs)).font(Type.bodyMD).foregroundColor(Ink.ash)
        )
    case .numbered(let n, let runs):
        return AnyView(
            HStack(alignment: .top, spacing: Space.md) {
                Text("\(n).").font(Type.bodyStrong).foregroundColor(Ink.ink)
                    .frame(width: 24, alignment: .leading)
                Text(inlineString(runs)).font(Type.bodyMD).foregroundColor(Ink.ash)
            }
        )
    case .bullet(let runs):
        return AnyView(
            HStack(alignment: .top, spacing: Space.md) {
                Text("•").font(Type.bodyStrong).foregroundColor(Ink.ink)
                    .frame(width: 16, alignment: .leading)
                Text(inlineString(runs)).font(Type.bodyMD).foregroundColor(Ink.ash)
            }
        )
    case .checkbox(let runs):
        return AnyView(
            HStack(alignment: .top, spacing: Space.md) {
                Text("☐").font(Type.bodyStrong).foregroundColor(Ink.mute)
                    .frame(width: 16, alignment: .leading)
                Text(inlineString(runs)).font(Type.bodyMD).foregroundColor(Ink.ash)
            }
        )
    case .blockquote(let runs):
        return AnyView(
            HStack(alignment: .top, spacing: Space.md) {
                Color(hex: 0x808080).opacity(0.4).frame(width: 3)
                Text(inlineString(runs)).font(Type.bodyMD).foregroundColor(Ink.mute)
            }
        )
    }
}

/// Wraps parsed blocks with stable identity so `ForEach` can render them.
struct IndexedBlock: Identifiable {
    let id: Int
    let block: ContractBlock
}

@MainActor
func indexedBlocks(from markdown: String, name: String) -> [IndexedBlock] {
    Contract.blocks(from: markdown, date: AppDate.longToday(), name: name)
        .enumerated()
        .map { IndexedBlock(id: $0.offset, block: $0.element) }
}
