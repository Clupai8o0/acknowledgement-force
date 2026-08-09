import 'theme.dart';

/// Fixture content. Every string here is product copy from FORCE-V2, not
/// lorem — the point of the spike is to see whether Force's actual sentences
/// survive contact with Flutter's text stack.

const kClaim = ['I am someone who trains', "when I don't feel like it."];

/// D9's locked mechanic: a proposed claim is always shown with the quote it
/// came from. If the AI can't cite you, it doesn't get to propose it.
const kAttributionLead = 'from what you said';
const kAttribution =
    '"the days I actually go are the days I almost didn\'t"';

const kMorningLead = 'this morning you said';
const kMorningQuote = '"gym after the 4pm shift"';

const kTranscript =
    'went after the shift. legs were dead, did the session anyway.';

class Day {
  const Day(this.label, this.mark, this.testimony, {this.tempo});

  final String label;
  final Mark mark;
  final String testimony;

  /// Numbers come from the source (D3). Force never asks whether you trained.
  final String? tempo;
}

/// The seven days behind today, oldest first.
const kRecord = <Day>[
  Day('WED 29 JUL', Mark.kept, 'pushed the squat session before work.',
      tempo: 'Tempo · 5 sets · 142 kg top'),
  Day('THU 30 JUL', Mark.broken, "didn't go. no excuse, just didn't.",
      tempo: 'Tempo · no session'),
  Day('FRI 31 JUL', Mark.kept, 'late but went. 40 minutes, all of it counted.',
      tempo: 'Tempo · 4 sets'),
  Day('SAT 1 AUG', Mark.unsettled, '—'),
  Day('SUN 2 AUG', Mark.kept, 'wanted to skip. went. easiest one all week.',
      tempo: 'Tempo · 6 sets · PR pull'),
  Day('MON 3 AUG', Mark.kept, 'shift ran over. went anyway, cut it short.',
      tempo: 'Tempo · 3 sets'),
  Day('TUE 4 AUG', Mark.kept, 'legs were dead. did the session anyway.',
      tempo: 'Tempo · 5 sets'),
];

/// Day 7: you sharpen the wording. These are the three sentences from D2,
/// in the order the argument makes them.
class ClaimDraft {
  const ClaimDraft(this.lines, this.verdict, this.reason, this.good);

  final List<String> lines;
  final String verdict;
  final String reason;
  final bool good;
}

const kDrafts = <ClaimDraft>[
  ClaimDraft(
    ['I am someone who takes', 'care of their body.'],
    'unfalsifiable',
    'any day can absorb it. a claim that cannot be broken cannot be kept.',
    false,
  ),
  ClaimDraft(
    ['I train four times', 'a week.'],
    'a habit in costume',
    'snaps the first week you get sick. that is a schedule, not an identity.',
    false,
  ),
  ClaimDraft(
    ['I am someone who trains', "when I don't feel like it."],
    'falsifiable',
    'today either contained a moment where you did not want to and went '
        'anyway, or it did not. you know which.',
    true,
  ),
];
