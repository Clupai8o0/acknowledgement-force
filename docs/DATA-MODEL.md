# Data model

**Derived from:** [`../FORCE-V2.md`](../FORCE-V2.md) — D2, D3, D4, D5, D6, D7, D8, D9, D12, D14, D16.
**Status:** the shapes are settled where the decisions settle them. Everything the decisions
do not cover is marked **UNDECIDED** and collected in [Open questions](#open-questions).

---

## Why this document exists

v1 kept a file called `acknowledgements.log`. It ran for 38 days and collected 145 rows.
Each row was a timestamp. From that file it is impossible to tell the best day of the seven
weeks from the worst one, because the app never recorded anything that could differ between
them (FORCE-V2 §0).

That is not quite the whole story, and the rest of it is worse. v1's in-memory model *did*
have a field for what you were going to do — `Acknowledgement.action`, "the user's
highest-leverage action", carried into a `HistoryEntry` of which "last 30 days are retained"
([`../force-old/Sources/ForceKit/Models/Models.swift`](../force-old/Sources/ForceKit/Models/Models.swift)).
It never produced a single bit of information either, because there was no second half of
the loop to compare it against. You said the thing in the morning; nothing ever asked
whether it happened.

So the job of this model is narrow and specific: **make the difference between a good day
and a bad day a thing the app can read.** Every table below exists because of a decision
that exists because of how v1 died.

Types are written in a Postgres-flavoured shorthand (`uuid`, `text`, `timestamptz`) because
that is the most legible notation, **not** because the database is chosen. It is not. See
[Open questions](#open-questions).

---

## What each decision forces on the schema

| Decision | Consequence for the model |
|---|---|
| **D2** — the unit is the identity claim | A `claim` with one sentence that can be *false*. Not a habit list, not a checklist of goals. |
| **D3** — evidence is produced, not asserted | An `evidence` row with a **source**, so the app can tell what you said from what Tempo saw. No `done: bool` anywhere. |
| **D4** — 1 primary + ≤2 background, 28-day pursuit | A `status` enum; a `pursuit` window that is a *separate row* from the wording, because the wording is editable and the pursuit is not; a permanent `retirement_receipt`. |
| **D5** — two beats, exactly one gate | `day.commitment` written in the morning, `day.settled_at` written at night. The morning is nullable; the evening is the one that closes the day. |
| **D6** — adaptive gate | All five conversation triggers must be answerable from stored rows alone, with no model call. |
| **D7** — three-state verdict | `kept` / `broken` / `unsettled`, and `unsettled` is **derived from absence**, never written by a button. |
| **D8** — lifecycle law | Every state-bearing fact is a timestamp. The logical day has a 4am boundary. No process-scoped booleans in gate logic, ever. |
| **D9** — commit night one, sharpen day seven | `source_quote` is **NOT NULL** on every proposed claim; wording history is append-only; day 7 and day 28 are scheduled reviews. |
| **D12** — nothing / question / trial | Consecutive misses are a **query**, not a stored counter. But the trial's *outcome* must persist, or the escalation state is process memory and D8 is violated again. |
| **D14** — web reads the record, native settles the day | Write permissions are per-field and per-surface, not per-table. |
| **D16** — per-claim illustration | One image asset per pursuit window, regenerated every 28 days. |
| **D24** — one image provider, one pipeline | `claim_image.provider` has a single value in practice and stays a column anyway, so a future switch is a data question. Generate-then-knock-out means `format` is `png_alpha`. |
| **D11 / §1b** — local-first, offline settle | Client-generated ids, a local outbox, idempotent server upserts. Nothing in the settle path awaits the network. |

---

## The shape at a glance

```
user
 ├── settings                        (day boundary hour, voice, strict mode)
 │
 ├── claim ─────────────┬── claim_revision      append-only wording history
 │                      ├── claim_candidate     night-1 proposals + the quote each came from
 │                      └── pursuit             the 28-day window; the part that is NOT editable
 │                            ├── claim_image   D16, one per window
 │                            ├── review        day 7, day 28
 │                            └── retirement_receipt   0 or 1, write-once, permanent
 │
 └── day  (one row per logical day, pointing at the claim it was lived under)
       ├── evidence[]                spoken / typed / external
       └── conversation?             present only when a D6 trigger fired
```

Read the arrows as "this is the thing that outlives that thing". A `day` keeps pointing at
the claim it was settled against even after that claim is retired — that is what makes a
retirement receipt readable a year later. You can see the 28 days the decision was built on.

---

## The one law: state is a timestamp (D8)

v1's gate read a `Bool`:

```swift
case .everyLaunch, .onLogin:
    return sessionAcknowledged     // a per-process Bool
```

`sessionAcknowledged` lived for the lifetime of the process. Force ran in the background,
you acknowledged, the flag went true, and then it stayed true through sleep, wake, and days
passing, because **a `Bool` has no clock** (D8). The gate silently never re-locked again.

The model-level rule that prevents this recurring:

> **Every fact that gate logic reads is a timestamp or is derived from one.** If you can
> name a boolean in gate logic, it is a bug.

Three corollaries that show up in every table below:

1. **There is no `is_settled` column.** There is `settled_at timestamptz`. Settled means
   non-null.
2. **There is no `unsettled` button.** `unsettled` is what a past day *reads as* when
   `settled_at` is null. Nothing writes it.
3. **Recomputation is idempotent** (D8). Deriving the state of the last 40 days a hundred
   times gives the same answer as doing it once, because it is a pure function of rows and
   the current wall clock.

---

## The logical day (D8)

The day boundary is **4am by default and configurable**. A gate answered at 12:30am on
Wednesday belongs to **Tuesday**, because that is the night you are closing. Shifts are
chaos; the clock has to match the life.

```
logical_date(instant, boundary_hour) =
    calendar_date(instant - boundary_hour hours)

# boundary_hour = 4
2026-08-04 23:10  ->  2026-08-04
2026-08-05 00:30  ->  2026-08-04     <- the same night
2026-08-05 03:59  ->  2026-08-04
2026-08-05 04:00  ->  2026-08-05     <- new day
```

`logical_date` is stored as a plain `date` on every day row, computed once at write time,
and never recomputed from the timestamp afterwards. Storing the derived key is what makes
the day addressable offline and makes `(claim_id, logical_date)` a usable idempotency key
for sync.

**UNDECIDED — whose clock.** The record fixes the boundary *hour* and says nothing about the
time zone. It matters concretely: the user has a Mac and an Android phone (D13), and the two
can be in different zones after a flight. The candidates are (a) the device's local zone at
write time, (b) a single home zone stored in settings, (c) the zone captured per day. v1 used
device-local `yyyy-MM-dd` keys
([`../force-old/Sources/ForceKit/Models/AppDate.swift`](../force-old/Sources/ForceKit/Models/AppDate.swift)).
Nothing in FORCE-V2 chooses. Until it does, store `settled_at` with its offset so the
decision can be made retroactively without losing information.

---

## Claim

The sentence you are defending. D2's test: **it names its own evidence, and it can be false.**

```
claim
  id                 uuid          client-generated
  user_id            uuid
  sentence           text          current wording; editable any time, zero friction (D4)
  status             enum          primary | background | retired
  created_at         timestamptz   when it was committed (D9, night 1)
  source_quote       text NOT NULL the user's own words it was derived from (D9)
  source_evidence_id uuid?         the yap/testimony the quote was lifted from, if stored
  retired_at         timestamptz?  set once, with a retirement_receipt
  updated_at         timestamptz   for sync LWW on sentence/status only
```

### `status` — and the counting rule

| Value | Meaning | Cardinality |
|---|---|---|
| `primary` | the claim the daily loop runs on; the one chosen by **what your mind is most willing to quietly drop** (D4) | exactly 1 |
| `background` | claimed and in the record, but not what the evening gate asks about | 0–2 |
| `retired` | pursued, then stopped, with a receipt | unbounded, grows forever |

D4 derives that count rather than imposing it: strip out every life area that has an
external enforcer — studies have deadlines, contract work has clients, DSEC has meetings —
and what is left is health, job hunt, and relationships. Three. One primary, two background.
The constraint is an output, not a rule someone picked.

The invariant `count(status = 'primary') == 1` is worth enforcing in the store, not just in
the UI, because the whole point of D4 is that burying the two things that need defending
inside six that don't is how they got lost in v1.

### `source_quote` is the mechanic, not a comment (D9)

Every claim the AI proposes must be shown with the phrase it came out of:

> **"I am someone who trains when I don't feel like it."**
> *from what you said: "the days I actually go are the days I almost didn't"*

D9 states the rule as: **if the AI can't cite you, it doesn't get to propose it.** In the
schema that is a `NOT NULL` constraint on `source_quote`, and it is load-bearing. Principle 5
says the user authors and the AI proposes; a claim with no attribution is the machine handing
you your identity, which is the one thing it may never do. Make it structurally impossible
to insert.

`source_evidence_id` points at the onboarding yap the quote was cut from, so the full context
is one join away and the quote itself can be verified rather than trusted.

### What is *not* on a claim

No score. No streak count. No completion percentage. No difficulty rating. D3 is explicit:
**the AI challenges, never grades** — an AI that scores you becomes an opponent you game or
resent. There is no column to game because there is no column.

---

## ClaimRevision — the wording history (D4)

The sentence is editable any time, at zero friction, because **rewording until it's true is
the work** (D4). You will rewrite a claim five times before it fits. That means the edit is
not a correction to be overwritten; it is a record of you converging on something.

```
claim_revision
  id           uuid
  claim_id     uuid
  sentence     text          the wording as of this revision
  written_at   timestamptz
  reason       enum          initial | free_edit | day7_sharpen | trial_rewrite
  review_id    uuid?         set when the edit came out of a scheduled review
  conversation_id uuid?      set when it came out of a D12 trial
```

Append-only. `claim.sentence` is a cached copy of the newest revision so the gate never
needs a join at 11pm.

`reason` matters because the three edits are different events with different weight. A
`day7_sharpen` happened after a week of real evidence including at least one bad day (D9).
A `trial_rewrite` happened after three consecutive misses, when the app asked *"is this claim
wrong, or is this week wrong?"* and you answered "the claim" (D12). A `free_edit` is you at a
bus stop deciding a word was off. Reading them back as one undifferentiated list loses the
thing worth reading.

---

## ClaimCandidate — night one (D9)

On night 1 you yap, the AI proposes 2–3 candidates, you pick one and edit it until it sounds
like you. The candidates you *didn't* pick are cheap to keep and occasionally revealing.

```
claim_candidate
  id            uuid
  user_id       uuid
  proposed_at   timestamptz
  sentence      text
  source_quote  text NOT NULL   same rule as claim.source_quote (D9)
  chosen        bool            exactly one true per onboarding round
  became_claim_id uuid?
```

`chosen` is the one place a boolean is fine — it is a fact about a past event, not gate
state.

**Onboarding input, not a blank page (D9).** v1's contract is 160 lines of the user that
already exist in `force-old`. The first session reads it and brings it as material. Whether
the contract text is imported as a stored artifact or read once and discarded is
**UNDECIDED**; the deferred list has it as "Migration: read the v1 contract +
`acknowledgements.log` as onboarding material" and no more.

---

## Pursuit — the part that is not editable (D4)

D4's asymmetry is the reason this is its own row:

- The **sentence** is editable any time, zero friction.
- The **pursuit** is locked for **28 days**. Exiting costs one spoken receipt.

Two different lifetimes, so two different rows. A claim whose wording changed nine times has
one pursuit; the lock is on the commitment, not the words.

```
pursuit
  id           uuid
  claim_id     uuid
  index        int           1, 2, 3… the nth 28-day window on this claim
  started_on   date          logical date of the commit night (D9: "the 28-day clock starts here")
  ends_on      date          started_on + 27 days
  closed_at    timestamptz?
  outcome      enum?         continued | retired
```

### Day numbering, stated explicitly

FORCE-V2 says "Night 1", "Day 7", "Day 28" and never does the arithmetic. **The convention
this document adopts** (a modelling choice, not a decision in the record):

```
day_index = (logical_date - pursuit.started_on) + 1

commit night   -> day 1
first review   -> day 7   = started_on + 6
retire window  -> day 28  = started_on + 27
```

### Why windows repeat

D16 says the per-claim image is "regenerated every 28 days", which is the only place the
record implies a pursuit renews rather than simply ending. So `pursuit` carries an `index`
and a claim can have several.

**UNDECIDED — what day 28 actually does.** The deferred list is blunt: *"28-day review ritual
— needs its own design; it's the moment claims live or die."* Two specific gaps:

1. If you keep the claim at day 28, does a new pursuit open automatically, or does something
   have to be chosen?
2. Is retirement only available *at* a window boundary, or any time after the first 28 days
   have elapsed? D4 rejects "locked 28 days but changeable any time" — but that rejection is
   about the lock period, and it does not settle behaviour on day 40.

---

## Day

One row per logical day. This is where the loop's two beats land (D5).

```
day
  id                 uuid
  user_id            uuid
  claim_id           uuid          the claim this day was lived under
  pursuit_id         uuid
  logical_date       date          4am boundary applied (D8)

  -- morning beat (D5, ~10 seconds, no lock)
  commitment         text?         "the single thing today that would count as evidence"
  committed_at       timestamptz?  null = you skipped the morning; that is data, not an error
  commitment_edited  bool?         see "modelling choices" below

  -- evening beat (D5, the wall)
  settled_at         timestamptz?  null on a past day = unsettled (D7)
  verdict            enum?         kept | broken   -- never 'unsettled'; see below
  testimony_evidence_id uuid?      the spoken/typed sentence that settled it

  -- the morning after an unsettled night (D7 rule 3)
  followup           enum?         bad_day | busy_day
  followup_at        timestamptz?

  updated_at         timestamptz
```

`commitment` may be null. D5 makes the morning a briefing, not a trial — no lock, so it can
be skipped. Its absence is meaningful: D5 notes the morning is *"what makes the evening beat
measurable, since 'did I do what I said' requires that you said something."* A day with no
commitment can still settle honestly; it just cannot be checked against anything.

`(claim_id, logical_date)` is unique, and it doubles as the sync idempotency key.

---

## The verdict: three states, and why the third one is not optional

D7 fixes the enum:

| State | Meaning | How it gets written |
|---|---|---|
| `kept` | you did it, evidenced | written with `settled_at`, at the gate |
| `broken` | you engaged and failed, spoken | written with `settled_at`, at the gate |
| `unsettled` | you didn't answer | **never written.** Read from `settled_at IS NULL` on a day that is over |

There is a fourth thing the UI has to render and it is not a verdict:

```
verdict_of(day, now) =
    day.verdict                      if settled_at is not null
    'unsettled'                      if settled_at is null and the logical day has ended
    'open'                           otherwise
```

`open` is today, before you have faced it. It must never render as `unsettled`. Unsettled
means *you didn't show up*, and that cannot be true at 9pm on a day you still have hours of.

### Why collapsing `unsettled` into `broken` corrupts the record

D7 states the principle: **broken means you showed up and lost; unsettled means you didn't
show up.** Four concrete consequences of merging them:

1. **A week of six broken days and a week of six unsettled days would look identical, and
   they are opposites.** The first is a person fighting and losing — and D12 says the app's
   correct response to that is *nothing*, genuinely nothing. The second is the app dying.
2. **The dying case is the one v1 could never see about itself.** The final acknowledgement
   was 10 July. Nobody noticed for 25 days, until someone opened a log file (FORCE-V2 §0).
   A run of unsettled days is the single most diagnostic signal this product can produce, and
   merging the states deletes it.
3. **They have different follow-ups.** The morning after an unsettled night asks one smaller,
   different thing — *"Bad day, or busy day?"* — two taps (D7 rule 3). There is no equivalent
   question after a broken day, because a broken day already has its answer: you spoke it.
   `day.followup` is therefore only ever populated on unsettled days, which is impossible to
   express if the states are one value.
4. **You would have to un-merge them anyway, badly.** A broken day has an `evidence` row
   attached; an unsettled day has none. Merging the enum means recovering the distinction by
   checking whether evidence exists — which is exactly the derivation you were trying to
   avoid, done less reliably.

And the merge buys nothing. The escalation rule needs "was there a miss", which is the union
of the two (D12: *"1st miss (`broken` or `unsettled`)"*) — one predicate. Keeping the states
separate costs a single enum value and preserves the diagnosis.

### Never-miss-twice is a query, not a column (D12, Principle 6)

```
misses(user) = days ordered by logical_date desc
               where verdict_of(day) in ('broken', 'unsettled')
               and the run is consecutive
```

| Consecutive misses | App behaviour | Stored? |
|---|---|---|
| 1 | **Nothing.** No colour change, no "streak broken", no gentle reminder. Silence. | nothing to store |
| 2 | The gate opens into conversation and asks about the *pattern*, not the day | a `conversation` row |
| 3 | **The claim goes on trial** — *"Is this claim wrong, or is this week wrong?"* | a `conversation` row with an outcome |

There is deliberately no `consecutive_misses int` column. A counter is a cached derivation
that can drift out of sync with the rows it summarises — the same class of bug as
`sessionAcknowledged` (D8), just slower to show up. Derive it every time; it is a scan over
at most a few dozen rows.

D12's reasoning for the empty first row belongs next to the schema: *if one bad day
produces any visible reaction, you learn the app is watching for failure — and then the
cheapest way to avoid the reaction is to stop opening it.* Nothing is a feature. There is a
line in the deferred list that says so explicitly: **"Verify nothing visible happens on a
first miss. Not a colour, not a word."**

### UNDECIDED — is there a `partial`?

D5 says the day settles as **kept / partial / broken**. D7, the palette note in FORCE-V2 §4,
and the spike spec ([`../spikes/SPEC.md`](../spikes/SPEC.md)) all say **kept / broken /
unsettled**. That is three places against one, and D7 is the later and more worked-out
decision, so this document uses the three-state enum. But `partial` appears in the record and
was never explicitly retracted. **It needs a call before the enum is built**, because adding
a state after days exist is a migration and a palette change.

---

## Evidence (D3)

D3's floor is **spoken testimony**: one sentence in your own words naming what actually
happened. Speaking it aloud puts it back through your own ears — that is the mechanism, not
the input method. Typing exists for when you are in public.

```
evidence
  id            uuid
  day_id        uuid?          null for onboarding yaps, which precede any day
  claim_id      uuid?
  kind          enum           spoken | typed | external
  produced_at   timestamptz

  -- user-produced
  text          text?          the transcript, or what was typed
  audio_ref     text?          UNDECIDED whether audio is retained at all — see below
  duration_ms   int?

  -- externally sourced
  source        text?          e.g. 'tempo'
  source_kind   text?          session | set | pr | volume
  source_ref    text?          the sibling app's own id for the thing
  fetched_at    timestamptz?
  payload       jsonb?         opaque snapshot as returned by the source
```

### User-produced vs externally sourced — and why the column matters

| | Produced by the user | Sourced externally |
|---|---|---|
| Examples | the spoken sentence, the typed sentence | Tempo sessions, sets, PRs, volume |
| Can be wrong? | yes — you can say you trained when you didn't | it is a reading, not a claim |
| Who wrote it | you | the sibling app |
| What it is for | the mechanism (D3: hearing yourself say it) | the numbers, so Force never has to ask |

D3: **numbers come from the source.** Force should never ask whether you trained. It should
already know, and open with the consequence.

Keeping `source` on the row is what makes D6's third conversation trigger possible at all:
*"Tempo contradicts you — you said you trained, there's no session."* That comparison needs
the user's account and the machine's account sitting in the same table, each labelled with
where it came from. If external facts were merged into the day row as plain fields, the
contradiction would be unrepresentable.

### The standing suite constraint

The user is building several apps for themselves — Tempo (workout logging), Recall, Kiro,
Force. The long-term intent is one API so they all talk to each other, and FORCE-V2's
deferred list states the design rule directly:

> **Prefer reading a fact from a sibling app over asking the user.** Tempo→Force is the first
> instance and proves the pattern.

The `evidence` table is deliberately generic about `source` for this reason. A second sibling
adds rows, not columns.

**The Tempo payload shape is unknown to this document, on purpose.** FORCE-V2 records that
*no Tempo data has ever been read* — only the tool list and its one-line description were
visible. So `payload` is an opaque snapshot and the four `source_kind` values are the
categories D3 names (sessions, sets, PRs, volume), not field names. Inventing a Tempo schema
here would be exactly the kind of quiet fabrication this documentation set is meant to avoid.
Read the API before modelling it.

### Kinds

| `kind` | Status | Note |
|---|---|---|
| `spoken` | **decided** (D3, the floor) | voice-first; the transcript is the durable artifact |
| `typed` | **decided** (D3) | available when in public |
| `external` | **decided** (D3) | Tempo first |
| `photo` — a photographed page | **PROPOSED, not in the record.** D3 names voice and typing only. Listed here because it has been raised; it is not a decision and nothing should be built for it until it is one. |

**UNDECIDED — does audio survive?** The deferred list has *"Decide STT: on-device vs cloud.
Must degrade to something offline (D11)"* and stops there. That choice decides whether
`audio_ref` exists: on-device transcription can discard the recording immediately; a cloud
pipeline has to hold it at least long enough to upload. The transcript is the durable record
either way. Related and equally undecided: retention and encryption of transcripts, which
are the most sensitive rows in the whole schema.

---

## Conversation (D6, D12)

Most nights the gate is one question, you speak, it closes, roughly 30 seconds. It opens into
a real conversation only when the data earns it. D12 is explicit that the second-miss
escalation is *"already a D6 trigger; no new machinery"* — so all of it is one table.

```
conversation
  id          uuid
  day_id      uuid
  trigger     enum        broken_day
                        | vague_testimony
                        | tempo_contradiction
                        | second_consecutive_miss
                        | review_due
  opened_at   timestamptz
  closed_at   timestamptz?
  outcome     enum?       rewrote_claim | named_hostile_week | none
  review_id   uuid?       set when trigger = review_due
```

Every one of the five triggers is a moment where a human who cared about you would say
something. On every other night the app shuts up, and that silence is what buys it the right
to not shut up on those five (D6). The reason this is a table and not a runtime branch is
Principle 2: *if the gate is identical every night, you will learn to sleep through it.* You
cannot check that the gate is behaving unpredictably without a record of when it spoke.

`outcome` is the D12 trial result. **`named_hostile_week` has to persist**, because D12 says
the app then *"backs off instead of pushing"* — and app behaviour that changes based on
something not written down is process memory, which is the D8 failure exactly.

**UNDECIDED — what "backs off" means.** For how long, and which behaviours change. Nothing in
the record says. Until it does, there is no principled default here to write.

**UNDECIDED — are the AI's turns stored?** Two arguments that they should be: D3's example
push (*"that's the fourth day running you've written 'went gym'"*) is a once-only move that
needs to know it already fired; and Principle 3 — *the AI may only say things that are
impossible without your record* — is only auditable if you can read back what it said. The
record does not decide it.

---

## Review (D9)

```
review
  id           uuid
  pursuit_id   uuid
  kind         enum          day7_sharpen | day28_window
  due_on       date
  completed_at timestamptz?
  outcome      enum?         sharpened | unchanged | continued | retired
```

| Review | When | What is permitted | What is not |
|---|---|---|---|
| **Day 7 — sharpening** | `started_on + 6` | rewrite the wording, using a week of real evidence including at least one bad day | **you cannot retire at day 7** (D9) |
| **Day 28 — window** | `started_on + 27` | continue, or retire with a receipt | — |

D9's reasoning for having a day-7 review at all is the sharpest sentence in the decision
record and belongs next to the table: *every claim written on day one is written by the wrong
person. Day-one you is maximally motivated and has just spent twenty minutes thinking about
who they want to be; tired-you on day nineteen has to live with the sentence. Those two
people don't know each other.* v1's 160-line contract was the artifact of day-one you and
none of it survived contact with tired-you.

Note that D4 already permits rewording at any time. Day 7 is not new permission — it is the
first time the app **makes you look**.

**UNDECIDED — the weekly background-claim check.** The record specifies exactly two scheduled
reviews, day 7 and day 28, both on the pursuit of a claim. It says nothing about a weekly
cadence and nothing about how background claims are reviewed at all. The `kind` enum is
extensible and a `background_check` value would slot in without a migration of anything else,
but **no cadence should be invented here.** See the larger gap below.

### The background-claim gap

This is the biggest hole in the model. D4 gives you up to two
background claims. The record then describes the loop entirely in terms of *the* claim,
singular: the morning shows "your claim", the evening asks about "your claim", the day
settles against it. **Nothing in FORCE-V2 says what a background claim does day to day** —
whether it accumulates evidence, whether it can be broken, whether it appears at all between
reviews.

The model above reflects that honestly: `day.claim_id` points at the primary claim the day
was settled against, and background claims exist as rows with a status and a pursuit and no
daily machinery. If background claims turn out to need their own days or their own evidence,
that is a schema change and it should follow a decision, not precede one.

---

## Retirement receipt (D4)

Retiring a claim costs one spoken receipt: **what the evidence showed, and why you're
stopping.** It goes into the record permanently.

```
retirement_receipt
  id             uuid
  claim_id       uuid
  pursuit_id     uuid
  spoken_at      timestamptz
  evidence_id    uuid NOT NULL    the spoken receipt itself (kind = spoken | typed)
  what_it_showed text NOT NULL    what the evidence showed
  why_stopping   text NOT NULL    why you're stopping

  -- the record snapshot, frozen at retirement
  days_total     int
  days_kept      int
  days_broken    int
  days_unsettled int
  sentence_at_retirement text NOT NULL
```

**Write-once. No update path, no delete path, no soft delete.** Not on the client, not in the
API, not from the web dashboard.

D4's reason is not punitive and the wording matters:

> not as punishment, but because a log of what you've abandoned and why is the most useful
> document about you that could exist.

That is a claim about the *value* of the row, and it is the entire justification for making
it immutable. A receipt you can quietly delete when it embarrasses you is not a record; it is
a draft. The counts are frozen at retirement rather than recomputed later so the receipt
reads the same in five years as it did the night it was spoken, even if the underlying day
rows are ever migrated or re-derived.

The `sentence_at_retirement` snapshot exists for the same reason: the wording was editable
right up to the moment you stopped (D4), so the receipt has to carry the version you actually
gave up on, not whatever the claim row says today.

---

## Per-claim illustration (D16)

One image per pursuit window: generated once at commit, regenerated every 28 days from the
user's own sentence and yap. Because it is rare and always changing, it cannot become
wallpaper.

```
claim_image
  id            uuid
  pursuit_id    uuid
  generated_at  timestamptz
  prompt        text          built from the claim sentence + the user's yap
  provider      text          one value in practice (D24) — kept as a column, see below
  asset_ref     text          blob/CDN reference, not inline bytes
  format        enum          svg | png_alpha
```

Where it may appear, from D16: the claim surface, the record, reviews, onboarding.
**Never the evening gate** — decoration there is the app patting you on the head at the moment
it should be taking you seriously.

**Provider: decided (D24). Format: follows from it.** D24 says stay with what produced the
approved samples — one provider, one pipeline, revisit at thousands of users. Native
transparency was the only reason a shortlist existed and it turned out to be unnecessary: for
black line art on white, luminance thresholding beats a segmentation model, which eats thin
hatch lines. So the pipeline is generate-then-knock-out and `format` is `png_alpha`; `svg` only
becomes reachable if a vector provider is ever revisited, which D24 defers to scale.

`provider` stays in the schema even though it has one value today. It is the column that makes a
future switch a data question rather than an archaeology question — every image already stored
says what made it.

**Still open: the exact model ID**, which D24 says to confirm at wiring time. Imagen 4 shut down
2026-08-17 and it is a different model from the Gemini image model the samples came from.
[`../spikes/illustration/COSTS.md`](../spikes/illustration/COSTS.md) prices the wider field and
goes stale fast. One storage note that is a finding rather than a preference: Vercel
caps function request/response bodies at **4.5 MB**, so the image must be streamed to blob
storage and referenced by URL, never returned inline. That is why `asset_ref` is a reference
and not bytes.

---

## Settings

Only the fields the decisions actually pin down.

```
settings
  user_id            uuid primary key
  day_boundary_hour  int      default 4          (D8 — configurable, default 4am)
  voice              enum     warm | flat | dry | hard   (D11 — 4 options, chosen for stance)
  strict_mode        bool     default false      (D12 — lives in settings, never auto-offered)
  updated_at         timestamptz
```

D11 leaves one thing open on purpose and it is worth prototyping before this table hardens:
**voice choice and the register dial may be the same control.** You pick a voice and the
voice *is* the register, so you hear what you're signing up for instead of reading an
adjective. If that resolves as one control, `voice` stays a single column. If not, a
`register` column joins it — and the parked note says the register dial would be *locked for
the 28 days*, which makes it a property of the pursuit rather than of settings. Unresolved.

`strict_mode` carries a distribution consequence that is not visible from the field name:
enabling it requires a LaunchAgent, which requires the macOS sandbox off, which takes Force
off the Mac App Store ([`../spikes/strict-mode/FINDINGS.md`](../spikes/strict-mode/FINDINGS.md)).
**D21 makes that call in strict mode's favour** — Force ships from GitHub with Developer ID
signing and notarization, not through the store — so the field costs nothing to keep.

---

## Who may write what (D14)

D14 splits the surfaces, and the split is per-field:

| Field | Native app | Web dashboard |
|---|---|---|
| `day.settled_at`, `day.verdict`, testimony | **write** | **never** |
| `day.commitment` | write | never |
| `claim.sentence` (and a new `claim_revision`) | write | **write** — wording only |
| `claim.status`, `pursuit`, `retirement_receipt` | write | **never** — these are commitments |
| everything, read | read | read — the full record, progress, statistics |
| account, billing | — | write |

> **Why the gate can never live on the web:** if you can settle your day in a browser tab, the
> gate loses scarcity, and you'd settle days half-watching something else. That is
> reflex-ticking with extra steps — v1's death reproduced faithfully in a new medium. (D14)

This is an authorization rule, so it belongs in the API layer, not only in the UI. A web
client that can `PATCH /day` at all has already lost the property.

---

## Sync

### The requirement

Two lines from the constraints, and they pull against each other until you notice they don't:

- **Cloud sync + restore.** State lives on a server, not only on the device. (§1b)
- **The day settles with or without the network.** *Offline or API down, the day still settles
  and something still gets said. The gate never depends on a network call.* (D11)

Plus the tension flagged in §1b: *any design where you wait on a spinner before you can speak
is disqualified.*

### The invariants that follow

1. **The settle write is local, synchronous, and complete before any pixel changes.** No
   network call is in the path between releasing the record button and the day being closed.
2. **Every id is generated on the device.** An offline write needs an identity before a server
   has ever seen it. (uuid v7 is the obvious pick for sortability — a modelling choice, not a
   decision.)
3. **Server writes are upserts keyed on the client-generated id.** Retry after a dropped
   connection is safe by construction. This is D8's idempotence rule applied to the wire:
   sending the same write a hundred times equals sending it once.
4. **Model responses stream in *after* the day is already settled.** The verdict is never
   waiting on a token. (§1b)
5. **A local outbox holds pending writes.** It is local-only and never itself synced.

```
outbox                       -- local only, never leaves the device except as its payload
  id           uuid
  entity       text          'day' | 'evidence' | 'claim_revision' | ...
  entity_id    uuid
  op           enum          upsert | append
  payload      jsonb
  queued_at    timestamptz
  attempts     int
  last_error   text?
```

### Conflict rules, by table

Most of this model is append-only, which is why sync is not hard here.

| Table | Rule | Why it works |
|---|---|---|
| `evidence`, `claim_revision`, `conversation`, `claim_candidate`, `retirement_receipt` | append-only, union by id | two devices never write the same row; there is nothing to merge |
| `day` | unique on `(claim_id, logical_date)`; **earliest `settled_at` wins** | you settle a night once, and the gate is native-only (D14). A conflict here means two devices both settled the same night offline — rare, and the honest resolution is the one that happened first. Log the loser rather than dropping it silently |
| `claim.sentence`, `claim.status` | last write wins on `updated_at` | LWW cannot destroy history, because history is a different (append-only) table |
| `pursuit` | append-only; `closed_at`/`outcome` set once | the pursuit is the part that is not editable (D4) |
| `settings` | last write wins | low stakes |

### Clock and provenance

The device writes `settled_at` from its own wall clock, because the logical day is defined
against the user's local time (D8). The server records `received_at` alongside it and
**never rewrites a user timestamp**. If the two disagree wildly, that is a fact worth having,
not a fact worth silently correcting.

### Restore

A fresh device pulls the full record and is complete, because nothing is ever only local —
with two exceptions to state plainly: the `outbox` (local by design) and raw audio, if it
turns out to exist at all (**UNDECIDED**, above).

### Retention

Nothing in FORCE-V2 sets a retention limit, and two decisions require the opposite: D4 says
the retirement receipt is permanent, and §2 gives the Counsel a sentence it can only say with
long history — *"you've claimed this for nineteen days and defended it four times."* So the
working assumption is **nothing is deleted**. v1's 30-day history cap
(`HistoryEntry`, "last 30 days are retained") does **not** carry forward. Flagged as an
assumption rather than a decision, because no line in the record states it.

### The backend itself

**UNDECIDED, and this is the big one.** What the record fixes:

- **Hosting is Vercel.** Any web surface or server component deploys there. (§1b, hard
  constraint)
- The deferred list has one line for the whole layer: *"Vercel: API, auth, sync endpoint,
  model calls, web dashboard, landing."*

What the record does **not** fix:

| Question | v1's answer (history, not precedent) | v2 |
|---|---|---|
| Database | Supabase Postgres, single `contents` row per user, RLS on `auth.uid() = user_id` | **undecided** |
| Auth | Supabase GoTrue, email + password; session in the macOS Keychain, 0600 file on CLI | **undecided** |
| Client↔DB path | apps talked **directly** to Supabase with the public anon key; the web app went through Next.js | **undecided** |

The shapes above assume a relational store because the model is relational and v1's was
Postgres. Nothing in it needs anything exotic — no extensions, no full-text search, no
vectors. Whichever way the choice goes, the client-side invariants (local first,
client-generated ids, idempotent upserts) do not change, which is why they are stated here
and the backend is not.

**UNDECIDED — does the v1 API-key / MCP surface carry forward?** v1 shipped both:

- `api_keys` — one row per token, **sha256 hash stored, raw key shown exactly once**, a `prefix`
  column for display, per-scope arrays, `revoked_at` / `expires_at` / `last_used_at`
  ([`../force-old/web/supabase/migrations/0002_api_keys.sql`](../force-old/web/supabase/migrations/0002_api_keys.sql)).
  The `fc_live_<24-byte-base62>` CSPRNG format is specified in
  [`../force-old/plans/roadmap.md`](../force-old/plans/roadmap.md) Track 1, not in the migration.
- `@force/mcp` — an MCP server exposing `get_contract`, `update_contract`, `list_quotes`,
  `set_goals`, `get_reflection` and friends
  ([`../force-old/mcp/README.md`](../force-old/mcp/README.md)).

Every one of those tools operates on v1 nouns — contract, quotes, goals, reflection — and
**none of those nouns exist in v2.** FORCE-V2's deferred list says only: *"MCP server from
`force-old/mcp` — re-point at the v2 data model once it exists."* So the question is live and
it is really two questions:

1. Does the **key mechanism** carry forward? It was well built and is cheap to keep.
2. Does the **write surface** carry forward? An MCP tool that can write a `day.verdict` would
   let an agent settle your night, which is D14's browser-tab problem with the human removed
   entirely. Read-only access to the record is a different proposition from write access to
   the loop, and the record does not distinguish them because it has not been asked.

---

## Deliberate absences

Things a habit tracker would have that this model does not, each with the decision that
removed it.

| Not present | Why |
|---|---|
| `score`, `rating`, `grade` | D3 — the AI challenges, never grades. *An AI that scores you becomes an opponent you game or resent, and you can lie to it for free.* |
| `streak` / `consecutive_days` | Principle 6 and the research doc — streaks done wrong cause "streak creep" and one break causes total abandonment. What matters is the last two days, and that is a query. |
| `completion_percent` | D2 — a claim is not a chore with a fill level. Today either contained the moment or it didn't. |
| `is_acknowledged: bool` | D8 — this is the exact field that killed v1. |
| `habits[]` / `checklist[]` | D2 and D1 — v1 had 8 daily non-negotiables and 6 priority areas, and it was too large to internalise. *Disqualified: the checkbox. It is literally v1.* |
| `reminder_time` | D5 rule 3 — the evening beat is day-close-based, not clock-based. Shifts are chaos; some nights are 1am. |

---

## Modelling choices no decision forces

Clearly separated so nobody later mistakes joinery for a decision. None of these are in
FORCE-V2; all of them are cheap; each can be dropped without touching anything else.

| Choice | Rationale | Cost of dropping |
|---|---|---|
| `pursuit` as its own table | D4 makes wording and commitment two different lifetimes; one row cannot carry both cleanly | fold `started_on`/`ends_on` onto `claim`, lose window history |
| `day_index` counting the commit night as day 1 | the record says "Night 1 / Day 7 / Day 28" and never does the arithmetic; something has to be picked | shift by one everywhere |
| `commitment_edited` on `day` | D5 gives the morning a proposed default with "one tap to adjust"; knowing which happened is one bit, and reflex-accepting every proposal is exactly the pattern that preceded v1's death | drop the column |
| `unsettled_via: declined \| lapsed` (**not in the schema above**) | D7 has two paths to unsettled — tapping *Not tonight*, and never opening it — and treats both as `unsettled`. Distinguishing them is one bit and they are different behaviours. Left out above because the record explicitly says they are the same state; noted here so the option is visible | n/a |
| frozen counts on the retirement receipt | so the receipt reads identically in five years | recompute from days, accept drift |
| uuid v7 for ids | sortable, offline-generatable | any uuid |

---

## Open questions

Collected, with what each one blocks.

| # | Question | Blocks |
|---|---|---|
| 1 | **The backend.** Database, and whether clients talk to it directly. v1 used Supabase Postgres; v2 fixes only that hosting is Vercel. | migrations, the sync endpoint, everything server-side |
| 2 | **Auth.** v1 used Supabase GoTrue email+password with the session in the Keychain. Nothing in FORCE-V2 chooses for v2. | account creation, restore, the web dashboard |
| 3 | **Does the v1 API-key / MCP surface carry forward,** and if so read-only or read-write? Every existing tool operates on nouns v2 deleted. | the MCP re-point in the deferred list |
| 4 | **`partial` — a fourth verdict?** D5 says kept/partial/broken; D7 and two other places say kept/broken/unsettled. | the enum, the palette, every day row already written |
| 5 | **Time zone for the logical day.** The boundary hour is fixed; whose clock is not. | the day key, and every cross-device sync |
| 6 | **What background claims do day to day.** The loop is described entirely in terms of the primary claim. | whether background claims need days, evidence, or reviews |
| 7 | **The weekly background-claim check.** Not in the record at all; day 7 and day 28 are the only scheduled reviews. | the `review.kind` enum |
| 8 | **What day 28 does** if you keep the claim, and whether retirement is boundary-only or any-time-after-28. | `pursuit` renewal, the retirement path |
| 9 | **STT on-device vs cloud**, and therefore whether raw audio is stored, uploaded, or discarded. | `evidence.audio_ref`, retention, the offline path |
| 10 | **Transcript retention and encryption.** The most sensitive rows in the schema; the record says nothing. | privacy posture, restore, the web dashboard |
| 11 | **Are the AI's turns persisted?** Needed to fire a once-only push (D3) and to audit Principle 3. | the `conversation` table's shape |
| 12 | **What "the app backs off" means** after a hostile week is named (D12). Duration, and which behaviours change. | `conversation.outcome`'s consequences |
| 13 | **The image model's exact ID.** The provider is settled (D24 — stay with what produced the approved samples); the model ID gets confirmed at wiring time. | `claim_image.provider`'s single value |
| 14 | **What strict mode actually does** — interrupt on a schedule, or block chosen apps until the day settles. D18 proved capability; nothing decided behaviour. (The *distribution* half is closed: D21, GitHub + Developer ID.) | `settings.strict_mode`'s meaning |
| 15 | **Register dial** — separate from voice, or the same control (D11)? If separate, it is *locked for the 28 days*, which makes it a pursuit field, not a setting. | `settings.voice` vs a `pursuit.register` |

---

## See also

- [`../FORCE-V2.md`](../FORCE-V2.md) — the decision record. If this document and that one
  disagree, that one is right and this one is a bug.
- [`./ARCHITECTURE.md`](./ARCHITECTURE.md) — how the model is stored and moved on each surface.
- [`./PLATFORM.md`](./PLATFORM.md) — the platform layer that D8's lifecycle facts come from.
- [`./DESIGN.md`](./DESIGN.md) — how `kept` / `broken` / `unsettled` are rendered, and the
  palette problem they create.
- [`./COPY.md`](./COPY.md) — the words attached to these states.
- [`../plans/ROADMAP.md`](../plans/ROADMAP.md) — what gets built first.
- [`../spikes/strict-mode/FINDINGS.md`](../spikes/strict-mode/FINDINGS.md) — what the OS
  actually permits, and why D8 cannot be satisfied in Dart.
- [`../spikes/illustration/COSTS.md`](../spikes/illustration/COSTS.md) — image provider
  pricing behind D16.
- [`../force-old/web/supabase/migrations/`](../force-old/web/supabase/migrations/) — v1's
  schema, kept as history, not as precedent.
