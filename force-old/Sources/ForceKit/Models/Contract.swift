import Foundation

// The daily contract, modeled as typed blocks. It is authored as plain
// Markdown (editable in Settings / the web editor) and parsed into blocks so
// each front end can render it natively (SwiftUI views, terminal text).
// {{DATE}} and {{NAME}} are substituted at render time.

/// One block-level element of the rendered contract.
public enum ContractBlock: Equatable, Sendable {
    case h1(String)
    case h2(String)
    case h3(String)
    case rule
    case paragraph([Inline])
    case numbered(Int, [Inline])
    case bullet([Inline])
    case checkbox([Inline])
    case blockquote([Inline])
}

/// An inline run within a block — plain or bold text.
public enum Inline: Equatable, Sendable {
    case plain(String)
    case bold(String)
}

public enum Contract {
    /// Parses editable Markdown into renderable blocks.
    ///
    /// Supported line forms:
    ///   `# / ## / ###` headings · `---`/`***`/`___` rule · `1.` numbered ·
    ///   `- `/`* ` bullet · `[ ]`/`- [ ]`/`- [x]` checkbox · `> ` blockquote ·
    ///   `**bold**` inline · everything else is a paragraph.
    ///
    /// - Parameters:
    ///   - markdown: The contract source text.
    ///   - date: Replaces `{{DATE}}` occurrences.
    ///   - name: Replaces `{{NAME}}` occurrences.
    public static func blocks(from markdown: String, date: String, name: String = "") -> [ContractBlock] {
        let text = markdown
            .replacingOccurrences(of: "{{DATE}}", with: date)
            .replacingOccurrences(of: "{{NAME}}", with: name)
        var blocks: [ContractBlock] = []

        for raw in text.components(separatedBy: "\n") {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.isEmpty { continue }

            if line == "---" || line == "***" || line == "___" { blocks.append(.rule); continue }
            if line.hasPrefix("### ") { blocks.append(.h3(String(line.dropFirst(4)))); continue }
            if line.hasPrefix("## ")  { blocks.append(.h2(String(line.dropFirst(3)))); continue }
            if line.hasPrefix("# ")   { blocks.append(.h1(String(line.dropFirst(2)))); continue }

            // Checkbox — bare `[ ]` or task-list `- [ ]` / `* [x]`.
            if let body = checkboxBody(line) { blocks.append(.checkbox(parseInline(body))); continue }

            if line.hasPrefix("> ") { blocks.append(.blockquote(parseInline(String(line.dropFirst(2))))); continue }
            if line == ">" { blocks.append(.blockquote([.plain("")])); continue }

            if line.hasPrefix("- ") { blocks.append(.bullet(parseInline(String(line.dropFirst(2))))); continue }
            if line.hasPrefix("* ") { blocks.append(.bullet(parseInline(String(line.dropFirst(2))))); continue }

            if let (n, rest) = numberedPrefix(line) {
                blocks.append(.numbered(n, parseInline(rest)))
                continue
            }

            blocks.append(.paragraph(parseInline(line)))
        }
        return blocks
    }

    /// Extracts the label from a checkbox line, accepting an optional `- `/`* `
    /// list marker followed by `[ ]`, `[]`, or `[x]`. Returns nil if not a checkbox.
    private static func checkboxBody(_ line: String) -> String? {
        var s = Substring(line)
        if s.hasPrefix("- ") || s.hasPrefix("* ") { s = s.dropFirst(2) }
        for marker in ["[ ] ", "[] ", "[x] ", "[X] "] where s.hasPrefix(marker) {
            return String(s.dropFirst(marker.count))
        }
        return nil
    }

    /// Detects a leading `N. ` ordered-list marker.
    private static func numberedPrefix(_ line: String) -> (Int, String)? {
        guard let dot = line.firstIndex(of: ".") else { return nil }
        let digits = line[line.startIndex..<dot]
        guard !digits.isEmpty, digits.allSatisfy(\.isNumber), let n = Int(digits) else { return nil }
        let after = line.index(after: dot)
        guard after < line.endIndex, line[after] == " " else { return nil }
        return (n, String(line[line.index(after: after)...]))
    }

    /// Splits `**bold**` runs out of a line. Odd segments are bold.
    private static func parseInline(_ s: String) -> [Inline] {
        let parts = s.components(separatedBy: "**")
        var runs: [Inline] = []
        for (i, part) in parts.enumerated() where !part.isEmpty {
            runs.append(i % 2 == 1 ? .bold(part) : .plain(part))
        }
        return runs.isEmpty ? [.plain(s)] : runs
    }

    /// The stock contract a fresh install starts with.
    public static let defaultMarkdown = """
    # Acknowledgement Force Daily Contract
    **Date:** {{DATE}}
    **For:** {{NAME}}
    ---
    ## I. Who I Am
    I am **{{NAME}}**. I am building a high-leverage tech career in Australia while securing PR as early as possible. My success depends on **sustained performance**, not bursts of effort.
    ---
    ## II. Non-Negotiable Rules
    1. **Sleep 11pm-7am.** Without 7-8 hours, everything else collapses.
    2. **Anxiety needs systems, not willpower.** Box breathing, 5-4-3-2-1 grounding, structured journaling.
    3. **Avoidance creates lethargy.** Gaming and scrolling extend suffering. Real rest is deliberate.
    4. **Execution beats planning.** Commits, deployments, and documentation are the only valid measures.
    5. **One project at a time.** Finish before starting new.
    6. **DSEC: 5 hours/week max** unless it produces portfolio ROI.
    7. **Every decision aligns with PR.** Backend roles in Australian enterprise are the target.
    8. **Work shifts are chaos; systems adapt.** My schedule is unpredictable. I plan accordingly.
    9. **Burnout isn't honourable.** I monitor energy and adjust load proactively.
    ---
    ## III. Current Priorities (Q1 2026)
    **Academic:** High Distinction standard. Every assignment is a portfolio piece.
    **Technical:** Meta Back-End Cert (9 credits), AWS + Azure certs, Docker/Kubernetes, LeetCode (NeetCode Blind 75 + company-specific).
    **Portfolio:** Current project documented and deployed. All work public on GitHub.
    **Financial:** Save $400/week → MacBook Pro + Bali trip fund + etc...
    **Health:** Gym consistency established as non-negotiable routine.
    **Systems:** Anxiety management operational. Sleep restructured. Motion AI evaluated.
    ---
    ## IV. Daily Non-Negotiables
    **I will complete these every day:**
    [ ] Brush teeth (morning & night)
    [ ] Wash face (morning & night)
    [ ] LeetCode: 1 problem minimum
    [ ] Send 1 cold message/email to a professional or company
    [ ] Gym session or 30min physical activity
    [ ] Journal: 5-10 minutes (structured template)
    [ ] Read: 15-30 minutes (technical or strategic)
    [ ] **No doomscrolling.** Sit in silence instead (5-10 min minimum)
    ---
    ## V. What I Will Not Do
    - Stay up past midnight without explicit justification.
    - Run multiple side projects simultaneously.
    - Accept commitments without clear portfolio ROI.
    - Confuse busyness with progress.
    - Skip rest cycles for "grinding."
    - Ignore anxiety symptoms until lethargy hits.
    ---
    ## VI. Daily Acknowledgement
    **By opening this app, I acknowledge:**
    - I have read and understood all principles above.
    - I commit to executing with discipline and clarity.
    - I accept that sustainable performance requires protecting sleep, managing anxiety, and building demonstrable work.
    - I measure progress by outputs, not hours or plans.
    ---
    ## VII. Accountability
    **When I notice failure modes (skipping sleep, planning instead of doing, treating symptoms):**
    1. Stop immediately.
    2. Box breathing + 5-4-3-2-1 grounding.
    3. Structured journaling.
    4. Reassess with Claude.
    ---
    **I am {{NAME}}. I commit to this contract for today.**
    """
}
