# Copy and voice

In Force, the words are the feature.

That is not a slogan. It falls out of the shape of the product. The app shows you one
gate a night (D5), and on most nights it says one thing (D6). Strip out the illustration,
which is banned from the gate anyway (D16), and what is left on the screen that matters is
your sentence, your voice, and one line the app wrote. If that line is wrong, there is no
other feature standing behind it to carry the night.

v1 had 160 lines of copy and none of it worked, and the reason is specific: the words were
not badly written. They were *unpicturable*, and they were the same every morning. You cannot
habituate to a sentence you can see; you habituate to a sentence that slides off. See
[../FORCE-V2.md](../FORCE-V2.md) D1 for the full diagnosis.

This doc is the rule set. Sibling docs: [DESIGN.md](./DESIGN.md) for type, colour and
motion, [ARCHITECTURE.md](./ARCHITECTURE.md) for where the model sits relative to the
gate, [../plans/ROADMAP.md](../plans/ROADMAP.md) for what ships when.

## 1. The correction this whole doc is built on (D23)

A real exchange, and the origin of every rule below. It is now in the decision record as **D23**.

**Rejected:**

> Drop it now and you're not deprioritising a habit — you're retiring a claim four days
> early, without the receipt.

**Approved:**

> You started this 19 days ago. You've gone on 11 of them. There are 9 days left. Stop
> now and you never find out if it would have stuck.

The stated reason, verbatim:

> **"if I can't visualize it, it doesn't go in."**

That sentence is the whole thesis. Everything after this section turns it into checks that
someone who is not the user can run on a sentence before it ships.

**Why the first one fails.** Three abstractions in twenty-three words: *deprioritising a
habit*, *retiring a claim*, *the receipt*. Nothing in it can be pictured. You cannot see a
deprioritisation. Worse, it is a sentence about the *category* of the act rather than the
act — it corrects your framing instead of showing you your record, and correcting
someone's framing at 11pm is the most annoying thing a machine can do.

There is a number in it. *Four days early.* It does no work, because it is a modifier
hanging off the end of an abstraction you have already stopped parsing. **Concreteness is
not "contains a digit."** The concrete thing has to be the load-bearing part of the
sentence — the thing the sentence is *about* — not decoration attached to a concept.

**Why the second one works.** Three numbers, front-loaded, each one a fact only your
record contains: 19, 11, 9. You can hold all three. They arrive in the order you would
count them. Then the stake, and the stake is also picturable: *you never find out if it
would have stuck* — a future you can see yourself not having. Nobody is being corrected.
The app states the position and stops.

Note what the second sentence never does: it does not tell you to stay. It has no verb
aimed at you at all.

## 2. Plain words over clever ones

The decision record and the product are two different documents. `retire a claim`,
`receipt`, `pursuit`, `settle` and `unsettled-as-a-state` are how *we* talk about Force
while building it. Most of them must never reach a screen.

| Never say | Say |
|---|---|
| deprioritise | stop, drop |
| retire a claim | quit, stop saying it |
| miscalibrated | wrong for you |
| without the receipt | without saying why |
| adherence, compliance | whether you showed up |
| your journey, your wellness, your mindset | (nothing — cut the sentence) |
| reflect on your progress | here's the week, read it |
| leverage, utilise, robust, optimise | (banned outright, no replacement) |
| consistency is key, small steps, trust the process | (banned outright) |
| highest-leverage action | the thing you said you'd do |

That last row is real v1 copy. `force-old/Sources/Force/ContractView.swift:196` shipped
the label **TODAY'S SINGLE HIGHEST-LEVERAGE ACTION** above a text field. Three words of
management consulting sitting on top of the only genuinely concrete thing on the screen.

**Four words that stay, because they are load-bearing:** `kept`, `broken`, `unsettled`
(D7) and `claim` (D2). These are user-facing vocabulary. The app defines the first three
on screen, in plain language, right next to them — the wireframe does exactly this:
*"a day is kept, broken, or unsettled. unsettled is not broken. broken means you showed
up and lost."*

**British spelling**, matching the decision record: *behaviour*, *colour*, *realise*,
*prioritise*. The one exception is a direct quote of the user, which is reproduced exactly
as said.

**Digits, not words.** 19, not nineteen. 11 of them, not eleven. You can hold a digit at
a glance; a spelled-out number has to be read.

## 3. Every claim the app makes contains something you can picture

The test, applied to every string before it ships:

> **Could a screenshot of this sentence have come from any other app?**

If yes, it does not go in.

There are exactly three places a picturable thing can come from, and all three are in the
record:

1. **A number.** How many days, how many sessions, how many in a row, what the top set
   was. Numbers come from the source, never from a question — Tempo is already wired up
   (D3), so Force never asks whether you trained. It opens with the consequence.
2. **A day.** *Thursday.* *The 8-day gap.* *Four days running.* A named day is a thing you
   can locate in your own memory; "recently" is not.
3. **A thing that happened**, quoted from your own testimony. *"went gym"*. *"legs were
   dead, did the session anyway."* Quoted, never paraphrased — the moment you paraphrase
   someone's words back at them, they are listening to a machine's summary of themselves.

D11 says it in one line: **character comes from what it knows, not how it talks.** The
most powerful sentence Force can produce is *"third tired session this week, and you closed
this app after 1am on all three of those nights."* Nobody else on earth can say that. Dressing
that in a register makes it sound like content, and you already ignore content.

**Note what that sentence does not claim.** D11's example originally read *"…and you slept past
midnight before all three,"* and **D24 corrects it: Force has no sleep data and should not ask
for it.** The line stands on Force's own timestamps — when the app was closed — and nothing
else. Same insight, no health permissions, no tracking. Use the corrected wording. This is the
record test applied to the record test's own example: if a sentence needs a source Force does
not have, get the source or change the sentence.

## 4. The record test, and the right to say nothing

**The app may only say things that are impossible without your record.** That is
Principle 3, and it is a hard filter, not a preference.

Generic encouragement is banned outright. Not discouraged — banned. A talking fortune
cookie is worse than silence, because it costs the same attention and returns nothing, and
you will habituate to it *faster* than you habituated to the contract. It is the canned
mantra again, now with audio.

Specifically banned, in any phrasing:

- "That's okay, keep it up."
- "You've got this."
- "Great job!"
- "Tomorrow is a new day." / "Every day is a fresh start."
- "Don't be too hard on yourself."
- Anything that would still be true if the app had never read a single day of your record.

The research doc reached the same place from the evidence side: canned trait mantras
failed to replicate, and value-reflection tied to a concrete goal the user already entered
is what survives. See
[../force-old/docs/research-affirmations-habits-ai-mentor-v2.md](../force-old/docs/research-affirmations-habits-ai-mentor-v2.md) §1.

**Silence is a valid output.** This is stated in Principle 3 and it is not a fallback — it
is the default. The single largest instance of it is D12: on a first miss the app does
**nothing**. No colour change, no "streak broken", no gentle reminder. Zero words. If one
bad day produces a visible reaction, you learn the app is watching for failure, and the
cheapest way to avoid a reaction is to stop opening the app. That is exactly how v1 ended.

When there is nothing in the record worth saying, the correct copy is no copy.

## 5. The app never grades. It may challenge once.

No scores. No percentages framed as a result. No letter grades, no "78% adherence", no
weekly ranking against last week. An AI that scores you becomes an opponent you game or
resent, and you can lie to it for free (D3).

The app *states* the record. It does not rank it.

The one licence it has is to push, and D3 gives the shape:

> "That's the fourth day running you've written 'went gym' and nothing else. That's not a
> record, that's a signature."

Read what that sentence does. It contains a number (four), a day-span, and a verbatim
quote of the user. It makes no judgement about the training. It only observes what the
*testimony* has become. And it is a challenge you can answer.

**Once means once.** If the answer is "yeah, I know", the app drops it and closes the day.
Pushing twice on the same point is nagging, and nagging is the behaviour that gets an app
uninstalled at 1am. The five conditions that earn a push at all are fixed in D6: the day
settled broken, the testimony was vague, Tempo contradicts you, it's a second consecutive
miss, or the 28-day review is due. On every other night the app shuts up — and that is
precisely what buys it the right to not shut up on those five.

## 6. "I didn't" has to be a complete answer

D5, rule 2: *"I didn't" is a complete, valid, closeable answer.* If the only exit is
success, you will lie or you will stop opening it — and v1 shows which one you pick.

Copy consequences, all of them testable:

- **No prompt may be phrased so that failure has no grammatical answer.** *"What did you
  get done today?"* is a bad prompt — "nothing" doesn't fit it. *"What happened?"* is a
  good one, because "nothing, I didn't go" is a complete sentence in reply.
- **Never answer a broken day with a fix.** Broken is a closeable state, not a problem the
  app was waiting to solve. The correct response to a spoken, honest failure is to accept
  it and close. A day that closes as broken is worth more than a day that closes as kept.
- **The exit is a statement, not a dismissal** (D7). It says **Not tonight**. It does not
  say *Skip*, *Close*, *Later*, *Maybe tomorrow*, or *Remind me*.
- **No confirm dialog, no guilt copy, no "are you sure"** (D7, rule 1). One tap, closes
  instantly. The moment quitting the night gets expensive, you quit the app instead.
- **What comes back the next morning is a different, smaller question**, never the same
  one (D7, rule 3): *"Yesterday didn't settle. Bad day, or busy day?"* Two taps. Those two
  answers deserve completely different responses and it is the only distinction that
  matters.

## 7. Length (D23)

An earlier draft of this doc said "short sentences, one idea each." The user overturned it,
and the correction matters more than the original rule did, because "keep it short" is what
everyone reaches for and it is not the rule. **D23 now carries it in the decision record**, in
those words: the distinction was collapsed once and corrected.

**"Short sentences" is not the principle. Plain words and something picturable is.**

Length is allowed. Length is sometimes *wanted*, because more time on screen is more time
to visualise, and visualising is the entire mechanism. A long passage of concrete,
plain-worded prose about your own last four weeks is a good thing. A short abstract one is
not.

**What killed v1 was passive length.** 160 lines, 9 rules, 8 daily non-negotiables, 6
priority areas — scrolled past every morning by someone who had not chosen to read any of
it, in order to reach a checkbox (D1). The word count was not the failure. The failure was
that the reading was a toll, imposed on a schedule, and the toll was the same every day.

**Length only helps where the user chose to read.** That single distinction sets every row
below.

| Surface | How long | Why |
|---|---|---|
| The claim | **One sentence. Always.** | It has to be holdable in your head on a bad night, and it has to fit on the gate above the button (D2). |
| Morning beat | One line: the claim, and the one thing today that counts as evidence | ~10 seconds, a briefing not a trial (D5). |
| Evening gate | **Short by default, with an expandable "more"** | D6 locks the form: one prompt, you speak, it closes. The nights that earn a conversation get the words; the other nights never see them. |
| **What the user says** | **No limit. Ever.** | The testimony is the product. Truncating it, timing it out, or "keeping it brief" is the app grading the user's effort, which it does not do (D3). |
| Day-7 sharpening | Medium — enough to show what actually happened that week | You sat down for this. It is the first time the app makes you look (D9). |
| Reviews (day 7, day 28) | **Properly long** | Chosen, scheduled, sat-down-for. Illustration is allowed here too (D16). Day 28 is where a claim lives or dies (D4). |
| The Counsel | **Goes long** | You opened it because you are stuck. Its whole value is the argument being made properly. |
| First miss | **Zero words** | D12. Not brevity — absence. |

The rule underneath the table: **the app's own prose is short on surfaces it forced you
onto, and long on surfaces you chose.** The gate is forced. The review is chosen. That is
the only variable.

One hard floor from [DESIGN.md](./DESIGN.md) and D17: if a sentence only fits at 13px, the
sentence gets shorter. The type floor does not move. Force is designed to be opened on
your worst nights, when you are tired and not sharp — poor legibility is not an edge case
for this product, it is the core case.

## 8. Eight rewrites

Rows marked **(v1)** are real strings that shipped in Acknowledgement Force, from
`force-old/Sources/Force/ContractView.swift`. The rest are drafts that were rejected in
review. The "ships" column is wireframe copy from `spikes/flutter-showcase/lib/data.dart`
and the scene files, or product copy quoted in [../FORCE-V2.md](../FORCE-V2.md).

| Rejected | Ships | Why |
|---|---|---|
| "I have read and acknowledge this contract for today" **(v1)** | "HOLD TO SPEAK" — and above it, *this morning you said: "gym after the 4pm shift"* | A box can be ticked while your mind is elsewhere. That is the whole problem (D3). |
| "TODAY'S SINGLE HIGHEST-LEVERAGE ACTION" **(v1)** | "gym after the 4pm shift" | A superlative you have to evaluate, versus a place and a time you can see. |
| "Read carefully. Acknowledge intentionally." **(v1)** | *I am someone who trains when I don't feel like it.* / *from what you said: "the days I actually go are the days I almost didn't"* | Instructions about how to feel, versus your own sentence with your own mouth quoted under it (D9). |
| "You didn't complete your habit today." | *didn't go. no excuse, just didn't.* — the user's own testimony, shown back | The app does not narrate your failure. It shows what you said about it (D3). |
| "You have 1 unsettled day. Complete it now?" | "Yesterday didn't settle. Bad day, or busy day?" | Not the same question again. A smaller, different one, with two answers that deserve opposite responses (D7). |
| "Don't worry, everyone slips up! Tomorrow's a fresh start." | *(nothing — no colour, no word, no notification)* | First miss. Any visible reaction teaches you the app is watching for failure (D12). |
| "Your claim may need adjusting based on recent performance." | "Three in a row. Is this claim wrong, or is this week wrong?" | Two real options, both nameable out loud, neither of them a verdict on you (D12). |
| "You've been a little vague in your entries lately." | "That's the fourth day running you've written 'went gym' and nothing else. That's not a record, that's a signature." | A number, a span, and your own words. The observation is about the testimony, not about you (D3). |

Read the rejected column as a set. Every one of them is grammatical, polite, and
completely interchangeable with a hundred other apps. That interchangeability *is* the
defect.

## 9. Mechanics that are really copy decisions

**Attribution is a copy format, and it is locked** (D9). Every proposed claim is shown with
the quote it came from:

```
I am someone who trains when I don't feel like it.
from what you said: "the days I actually go are the days I almost didn't"
```

The attribution is the mechanic, not decoration. It is the proof the sentence came out of
your mouth rather than the model's. **If the AI can't cite you, it doesn't get to propose
it.** The quote is reproduced verbatim, including the mess — fillers, false starts,
lowercase. A cleaned-up quote is not a quote.

**The user authors; the AI proposes** (Principle 5). The app may never write a sentence in
your first person and hand it to you as yours without the quote under it. It offers
candidates; you pick one and edit it until it sounds like you. Rewording until it is true
*is* the work — you will rewrite a claim five times before it fits (D4).

**The voice is always interruptible** (D11), which is a copy constraint disguised as an
audio one: the first sentence must carry the point, because the user may kill it
mid-sentence. Never build to a conclusion. Say the thing, then explain it if there is
time.

**The offline line has to pass every rule here too.** On-device fallback is mandatory —
offline or API down, the day still settles and something still gets said (D11). "Something"
means a sentence built from the local record, or silence. It does not mean a stock phrase
kept in reserve, because a stock phrase is the fortune cookie with a worse excuse.

**Case conventions**, observed in the wireframe and not yet locked as decisions: the app's
own quiet prose is lowercase (*"a day is kept, broken, or unsettled."*); controls are
uppercase with real tracking (`HOLD TO SPEAK`, `KEPT`, `BROKEN`) at 14px minimum per D17;
the claim and *Not tonight* are sentence case. Confirm against [DESIGN.md](./DESIGN.md)
before treating any of this as fixed.

## 10. Things the app may never claim

**That you cannot get past it.** This one is sourced, not stylistic. On Android, any
foreground app calling `setHideOverlayWindows(true)` — Settings does, and so do system
permission dialogs — makes the gate vanish. On macOS, `kill -TERM` always wins, and Force
Quit and Activity Monitor both go through that path. See
[../spikes/strict-mode/FINDINGS.md](../spikes/strict-mode/FINDINGS.md) Q3 and Q6. Copy
promising an inescapable gate would be a lie, and it would be a lie about the exact
property D7 spent its whole argument removing.

**That it knows how you feel.** It knows what you said and what Tempo recorded, and nothing
else.

**A streak.** D12 bans *"streak broken"* outright on a first miss. Beyond that, the
research is explicit that long streaks become a loss-aversion trap where one break causes
total abandonment (research doc §3), so treat any streak framing as needing a decision
before it ships rather than as available by default.

## 11. Before any string ships

1. Could this sentence have come from another app? If yes, delete it.
2. Is there a number, a day, or a quote in it — and is that the thing the sentence is
   *about*, not a modifier on the end?
3. Is every word one you would use out loud, to a friend, sober, at 11pm?
4. Does it grade? Cut it.
5. Does it leave "I didn't" as a complete answer?
6. Is it on a surface the user chose, or one they were put on? Long is fine on the first,
   never on the second.
7. Does it need the user's record to be true? If not, the correct output was silence.

## Open

Genuinely undecided. Do not resolve these by writing copy that assumes an answer.

- **Whether the four voices change the words or only the delivery.** D11 locks four voice
  options chosen for stance (warm / flat / dry / hard) and flags voice-choice-equals-
  register-dial as an open question worth prototyping. The register dial itself is parked
  (FORCE-V2 §5). Until that is settled, write one set of words.
- **Review cadence between day 7 and day 28.** FORCE-V2 names day 7 (D9) and day 28
  (D4/D9) and no others. If a weekly review exists, the "properly long" rule applies to
  it; whether it exists is not decided.
- **How "more" is revealed on the evening gate.** A tap, a scroll, a second beat — the
  length rule is settled, the affordance is not. See [DESIGN.md](./DESIGN.md).
- **The Counsel's register.** The surface itself is **in v1 scope (D22)**, and D23 puts it in
  the "goes long" row. What is not decided is its register — how blunt it is, and whether it
  differs from the gate's.
- **The onboarding script.** D9 locks the structure (yap, 2–3 candidates, pick, edit,
  commit) and the attribution mechanic. Not a single word of it is written.
- **iOS notification copy.** Notifications and Live Activities are the only levers iOS
  has (`FINDINGS.md` §3), and iOS is a companion, not a gate surface. Undesigned.
- **Error and empty-state copy.** Undesigned. Note that "empty" is a real state here — a
  new user on night one has no record, and the record test (§4) means the app has almost
  nothing it is allowed to say.
- **Landing page and marketing register.** D14 puts the landing page on the web. Nothing
  about its voice has been decided, except that §10 binds it: the marketing copy may not
  claim a gate you cannot escape.
