package com.clupai.force.data

sealed class ContractBlock {
    data class H1(val text: String) : ContractBlock()
    data class H2(val text: String) : ContractBlock()
    data class H3(val text: String) : ContractBlock()
    object Rule : ContractBlock()
    data class Paragraph(val runs: List<Inline>) : ContractBlock()
    data class Numbered(val n: Int, val runs: List<Inline>) : ContractBlock()
    data class Bullet(val runs: List<Inline>) : ContractBlock()
    data class Checkbox(val runs: List<Inline>) : ContractBlock()
    data class Blockquote(val runs: List<Inline>) : ContractBlock()
}

sealed class Inline {
    data class Plain(val text: String) : Inline()
    data class Bold(val text: String) : Inline()
}

object Contract {
    fun blocks(markdown: String, date: String, name: String = ""): List<ContractBlock> {
        val text = markdown
            .replace("{{DATE}}", date)
            .replace("{{NAME}}", name)
        val blocks = mutableListOf<ContractBlock>()
        for (raw in text.split("\n")) {
            val line = raw.trim()
            if (line.isEmpty()) continue
            if (line == "---" || line == "***" || line == "___") { blocks.add(ContractBlock.Rule); continue }
            if (line.startsWith("### ")) { blocks.add(ContractBlock.H3(line.removePrefix("### "))); continue }
            if (line.startsWith("## "))  { blocks.add(ContractBlock.H2(line.removePrefix("## "))); continue }
            if (line.startsWith("# "))   { blocks.add(ContractBlock.H1(line.removePrefix("# "))); continue }

            checkboxBody(line)?.let { blocks.add(ContractBlock.Checkbox(parseInline(it))); continue }

            if (line.startsWith("> ")) { blocks.add(ContractBlock.Blockquote(parseInline(line.removePrefix("> ")))); continue }
            if (line == ">") { blocks.add(ContractBlock.Blockquote(listOf(Inline.Plain("")))); continue }
            if (line.startsWith("- ")) { blocks.add(ContractBlock.Bullet(parseInline(line.removePrefix("- ")))); continue }
            if (line.startsWith("* ")) { blocks.add(ContractBlock.Bullet(parseInline(line.removePrefix("* ")))); continue }

            numberedPrefix(line)?.let { (n, rest) ->
                blocks.add(ContractBlock.Numbered(n, parseInline(rest)))
                return@let
            } ?: run {
                blocks.add(ContractBlock.Paragraph(parseInline(line)))
            }
        }
        return blocks
    }

    private fun checkboxBody(line: String): String? {
        var s = line
        if (s.startsWith("- ") || s.startsWith("* ")) s = s.substring(2)
        for (marker in listOf("[ ] ", "[] ", "[x] ", "[X] ")) {
            if (s.startsWith(marker)) return s.substring(marker.length)
        }
        return null
    }

    private fun numberedPrefix(line: String): Pair<Int, String>? {
        val dot = line.indexOf('.')
        if (dot <= 0) return null
        val digits = line.substring(0, dot)
        if (!digits.all { it.isDigit() }) return null
        val n = digits.toIntOrNull() ?: return null
        if (dot + 1 >= line.length || line[dot + 1] != ' ') return null
        return n to line.substring(dot + 2)
    }

    private fun parseInline(s: String): List<Inline> {
        val parts = s.split("**")
        val runs = mutableListOf<Inline>()
        for ((i, p) in parts.withIndex()) {
            if (p.isEmpty()) continue
            runs.add(if (i % 2 == 1) Inline.Bold(p) else Inline.Plain(p))
        }
        return if (runs.isEmpty()) listOf(Inline.Plain(s)) else runs
    }

    val defaultMarkdown: String = """
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
        **Financial:** Save ${'$'}400/week → MacBook Pro + Bali trip fund + etc...
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
    """.trimIndent()
}
