import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// Dark palette lifted verbatim from force-old/Sources/Force/Theme.swift (.dark),
/// same set the flutter-gate spike used. Strictly monochrome, by design.
abstract final class Palette {
  static const base = Color(0xFF141515);
  static const containerLow = Color(0xFF1B1C1D);
  static const container = Color(0xFF222324);
  static const containerHigh = Color(0xFF2A2B2C);
  static const containerHighest = Color(0xFF313334);
  static const bright = Color(0xFF3A3C3D);
  static const ink = Color(0xFFF2F2F0);
  static const inkContainer = Color(0xFFC9C9C6);
  static const ash = Color(0xFFDADAD7);
  static const mute = Color(0xFF9A9E9F);
  static const stone = Color(0xFF60646A);
  static const outline = Color(0xFF3C3F40);
  static const outlineSoft = Color(0xFF2A2C2D);
  static const onPrimary = Color(0xFF141515);
}

/// Fraunces and Inter are both variable fonts and Flutter instantiates the fvar
/// *default* instance unless told otherwise. Fraunces' default is wght 900 /
/// opsz 9 — Black at caption optical size — so every style pins `wght` and
/// `opsz` explicitly. CoreText does optical-size mapping for free on the
/// SwiftUI build; Flutter does not, and this is the single sharpest edge in
/// porting Force's typography.
List<ui.FontVariation> v(double wght, double opsz) => [
  ui.FontVariation('wght', wght),
  ui.FontVariation('opsz', opsz),
];

/// Legibility floor, and it is a floor, not a target.
///
/// Force is opened on the nights you are least sharp — tired, late, after a
/// shift. That is not an edge case for this product, it is the *design case*.
/// A screen you have to lean into at 11pm is a screen you close. So:
///
///   · nothing a user is expected to read is below 15 px
///   · prose and anything conversational is 17 px
///   · uppercase tracked labels are 14 px minimum, with real tracking, because
///     tracked caps at small sizes are the worst legibility case there is
///   · every text colour clears 4.5:1 against `base` (#141515)
///
/// The last rule retired `stone` (#60646A) as a text colour — it measures
/// 3.03:1 on base and simply cannot be used for type. It survives as the fill
/// for a `broken` mark, where the 3:1 non-text minimum applies and it passes.
/// `mute` (#9A9E9F) is 6.77:1 and is now the quietest voice in the app.
///
/// Nothing here clamps [MediaQuery.textScaler]; the OS setting is honoured and
/// the layouts that reserve space scale their reserves with it.
abstract final class Face {
  static const display = 'Fraunces';
  static const ui_ = 'Inter';

  /// The claim. The one piece of type in the product allowed to be big.
  static final claim = TextStyle(
    fontFamily: display,
    fontSize: 30,
    height: 1.32,
    letterSpacing: -0.4,
    color: Palette.ink,
    fontVariations: v(430, 30),
  );

  static final claimSmall = TextStyle(
    fontFamily: display,
    fontSize: 26,
    height: 1.34,
    letterSpacing: -0.3,
    color: Palette.ink,
    fontVariations: v(430, 26),
  );

  static final title = TextStyle(
    fontFamily: display,
    fontSize: 24,
    height: 1.28,
    letterSpacing: -0.2,
    color: Palette.ash,
    fontVariations: v(450, 24),
  );

  static final closing = TextStyle(
    fontFamily: display,
    fontSize: 28,
    height: 1.22,
    color: Palette.inkContainer,
    fontVariations: v(450, 28),
  );

  /// Prose. Testimony, transcripts, anything the app says to you. 17 px.
  static final body = TextStyle(
    fontFamily: ui_,
    fontSize: 17,
    height: 1.55,
    color: Palette.inkContainer,
    fontVariations: v(400, 17),
  );

  /// Supporting prose. Still full sentences, so still read — 16 px, `mute`.
  static final meta = TextStyle(
    fontFamily: ui_,
    fontSize: 16,
    height: 1.55,
    color: Palette.mute,
    fontVariations: v(400, 16),
  );

  /// The quietest thing on screen. 15 px is the floor; it does not go lower.
  static final micro = TextStyle(
    fontFamily: ui_,
    fontSize: 15,
    height: 1.5,
    color: Palette.mute,
    fontVariations: v(400, 15),
  );

  /// All-caps eyebrow. 14 px with 2.2 of tracking — the tracking is doing
  /// legibility work here, not styling work.
  static final label = TextStyle(
    fontFamily: ui_,
    fontSize: 14,
    height: 1.4,
    letterSpacing: 2.2,
    color: Palette.mute,
    fontVariations: v(500, 14),
  );

  static final button = TextStyle(
    fontFamily: ui_,
    fontSize: 15,
    height: 1.3,
    letterSpacing: 2.4,
    color: Palette.ink,
    fontVariations: v(560, 15),
  );

  static final timer = TextStyle(
    fontFamily: ui_,
    fontSize: 15,
    letterSpacing: 0.6,
    color: Palette.mute,
    fontVariations: v(500, 15),
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  static final numeral = TextStyle(
    fontFamily: display,
    fontSize: 46,
    height: 1.0,
    color: Palette.ink,
    fontVariations: v(400, 46),
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}

abstract final class Metrics {
  static const gutter = 28.0;
  static const markSize = 10.0;
  static const markGap = 9.0;

  /// Minimum comfortable touch target.
  static const tap = 44.0;
}

/// The day's three closeable states (FORCE-V2 §D7).
enum Mark {
  /// You did it, evidenced.
  kept,

  /// You engaged and failed, spoken. Not the same as not showing up.
  broken,

  /// You didn't answer. The more diagnostic signal of the two failures.
  unsettled,
}

/// Motion constants. One place, so the whole app moves like one thing.
abstract final class Motion {
  /// The house curve. Fast out of the gate, long tail. Nothing in Force
  /// overshoots except the settle, which earns it.
  static const ease = Cubic(0.16, 1.0, 0.3, 1.0); // expo-out-ish
  static const easeSoft = Cubic(0.33, 0.0, 0.15, 1.0);
  static const easeIn = Cubic(0.55, 0.0, 1.0, 0.45);

  static const fast = Duration(milliseconds: 220);
  static const med = Duration(milliseconds: 420);
  static const slow = Duration(milliseconds: 760);
}
