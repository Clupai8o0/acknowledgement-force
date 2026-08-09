import Foundation
import ForceKit

/// Renders parsed ``ContractBlock``s as terminal text — the CLI counterpart
/// of the SwiftUI block views in the macOS app.
enum ContractRenderer {
    /// Renders the user's current contract with date/name substituted.
    static func render(settings: SettingsStorage) -> String {
        let blocks = Contract.blocks(
            from: settings.contractText,
            date: AppDate.longToday(),
            name: settings.displayName
        )
        return render(blocks)
    }

    static func render(_ blocks: [ContractBlock]) -> String {
        var lines: [String] = []
        for block in blocks {
            switch block {
            case .h1(let s):
                lines.append("")
                lines.append(Terminal.bold(s.uppercased()))
            case .h2(let s):
                lines.append("")
                lines.append(Terminal.bold(s.uppercased()))
            case .h3(let s):
                lines.append("")
                lines.append(Terminal.bold(s))
            case .rule:
                lines.append(Terminal.dim(String(repeating: "─", count: 60)))
            case .paragraph(let runs):
                lines.append(inline(runs))
            case .numbered(let n, let runs):
                lines.append("  \(n). \(inline(runs))")
            case .bullet(let runs):
                lines.append("  • \(inline(runs))")
            case .checkbox(let runs):
                lines.append("  [ ] \(inline(runs))")
            case .blockquote(let runs):
                lines.append("  │ \(inline(runs))")
            }
        }
        return lines.joined(separator: "\n")
    }

    private static func inline(_ runs: [Inline]) -> String {
        runs.map { run in
            switch run {
            case .plain(let s): return s
            case .bold(let s): return Terminal.bold(s)
            }
        }.joined()
    }
}
