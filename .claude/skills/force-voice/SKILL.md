---
name: force-voice
description: Write or edit any text a Force user will read or hear — screen copy, button labels, what the AI says at the evening gate, notification text, onboarding questions, error and empty states, day-7 and day-28 review text, Counsel replies, landing-page words, and example copy pasted into specs or docs. Use before writing any user-facing sentence, and whenever reviewing or rewriting existing copy for tone, clarity, or length.
---

# Force's voice

In this product the words **are** the feature. Force has no scores, no streak badge and no
character. All it has is a sentence at 11pm and whether the user believes it.

## The correction everything else comes from (D23)

The user rejected this line from the debate screen:

> **Before:** "Drop it now and you're not deprioritising a habit — you're retiring a claim
> four days early, without the receipt."

and approved this rewrite:

> **After:** "You started this 19 days ago. You've gone on 11 of them. There are 9 days
> left. Stop now and you never find out if it would have stuck."

Their reason, in their words: *"if they can't visualize it, then there is no point of this
app... if I'm not able to see something happening, if I'm not able to visualize it
manifesting in my head when I read the words, then those words are not gonna happen at
all."*

Both sentences carry the same idea. The second one has a number, a countdown, and a thing
that happens. The first wasn't too advanced for the reader — it was too clever for the job.

## Three rules

**1. Plain words** (D23). Never *deprioritise*, *miscalibrated*, *retire a claim*, *optimise*,
*leverage*, *robust*. Say **stop**, **wrong for you**, **quit**, **kept**, **broken**. If a
shorter word does the same work, the longer one is a mistake.

**2. Picturable.** Every sentence the app says needs something you can see: a number, a
date, a thing that happened. *"You closed this app after 1am on three nights this week"* is
a picture. *"Your consistency has slipped"* is not.

**3. It may only say what the record proves (Principle 3).** Generic encouragement —
*"that's okay, just make sure to..."* — is banned outright. That is v1's canned mantra with
audio attached, and the user habituates to it faster than they did to the contract.
**Silence is a valid output.** The one thing Force can say that nothing else on earth can
is *"third tired session this week, and you closed this app after 1am on all three of those
nights"* (D11, as corrected by D24). Anything a generic app could have said is content, and
the user already ignores content.

> **Use that wording, not the older one.** D11's example used to read *"…and you slept past
> midnight before all three."* **D24 corrects it: Force has no sleep data and must not ask for
> it.** The line claims only what Force's own timestamps prove — when the app was closed. Same
> insight, no health permissions, no tracking. If a sentence needs a source Force does not
> have, get the source or change the sentence.

## Length — "short sentences" is NOT the principle (D23)

An earlier draft of this rule said "short sentences, one idea each." The user overturned
it, and **D23 records the correction in the decision record**: *"'Short sentences' is NOT the
principle. Plain words and something picturable is."* Brevity was never it. More words on screen
means more seconds spent, and more seconds means more time to actually see the thing. **Length
is allowed, and sometimes wanted.**

The one hard limit comes straight from how v1 died: **a long thing you scroll past is worse
than a short thing you read.** The v1 contract was 160 lines. Length wasn't the problem —
*passive* length was. **Length only helps where the reader chose to read** (D23). It is earned
in the places the user came to read, and spent nowhere near the place they came to close.

| Where | Length | Why |
|---|---|---|
| **The claim** | One sentence, always | It has to be carried around in their head |
| **The evening gate** | Short by default, with a **"there's more"** they can open | Most nights they're tired; some nights they'll want it |
| **What the user says** | **No limit, ever** | Them speaking or writing at length *is* the mechanism |
| **The day-7 and day-28 reviews** | **Properly long** | This is where they sit down and read |
| **The Counsel** | Long | Same |

**Day 7 and day 28 are the only reviews the record names** (D9, and D4/D9). If you find
yourself writing copy for a *weekly* review, stop — that cadence is not decided, and neither
is anything between day 7 and day 28. See the Open section of [docs/COPY.md](../../../docs/COPY.md).

## Failure is copy too

- **"I didn't" is a complete, valid, closeable answer** (D5). If the only exit is success,
  they'll lie or stop opening the app.
- **"Not tonight" gets no confirmation, no guilt copy, no "are you sure"** (D7). One tap,
  gone. The moment quitting the night gets expensive, they quit the app.
- **First miss: say nothing.** Not a colour, not a word, not a gentle reminder (D12).
- **The AI challenges; it never grades** (D3). It may push once — *"that's the fourth day
  running you've written 'went gym' and nothing else"* — then it drops it.
- **It proposes; the user authors** (D9). A suggested claim always ships with the user's own
  quote attached. If it can't cite them, it doesn't get to say it.

Copy that is already right, for calibration: *"Yesterday didn't settle. Bad day, or busy
day?"* (D7) · *"Three in a row. Is this claim wrong, or is this week wrong?"* (D12)

## Run this on any sentence before it ships

1. Can I see it? Name the number, the day, or the thing that happened. If there isn't one, cut the sentence or find one.
2. Could a habit app with no record of this person have said it? Then delete it.
3. Is there a shorter, more ordinary word for anything in here?
4. Read it out loud as a tired person at 1am. Does it land, or does it need a second pass?
5. Is it long *because* this is a place they chose to read — or just long?
6. Does it grade, nag, or congratulate? All three are out.
7. Does it leave "I didn't" available as an answer?

Full version with more rewrites: [docs/COPY.md](../../../docs/COPY.md).
Decisions and their reasoning: [FORCE-V2.md](../../../FORCE-V2.md).
Type sizes that copy has to survive at: [docs/DESIGN.md](../../../docs/DESIGN.md) (D17).
