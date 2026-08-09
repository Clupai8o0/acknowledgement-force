import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// Dark palette lifted verbatim from force-old/Sources/Force/Theme.swift (.dark).
/// The spike is dark-only, so this is a flat set of constants.
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

/// Fraunces and Inter are both variable fonts, and Flutter instantiates the
/// fvar *default* instance unless told otherwise. Fraunces' default is
/// wght 900 / opsz 9 — i.e. Black at caption optical size — so every style
/// here pins `wght` and `opsz` explicitly. CoreText does the optical-size
/// mapping automatically on the SwiftUI build; Flutter does not.
List<ui.FontVariation> _v(double wght, double opsz) => [
  ui.FontVariation('wght', wght),
  ui.FontVariation('opsz', opsz),
];

abstract final class Face {
  static const display = 'Fraunces';
  static const ui_ = 'Inter';

  static final claim = TextStyle(
    fontFamily: display,
    fontSize: 44,
    height: 1.24,
    letterSpacing: -0.4,
    color: Palette.ink,
    fontVariations: _v(500, 44),
  );

  static final closing = TextStyle(
    fontFamily: display,
    fontSize: 30,
    height: 1.2,
    color: Palette.inkContainer,
    fontVariations: _v(500, 30),
  );

  static final meta = TextStyle(
    fontFamily: ui_,
    fontSize: 13,
    height: 1.55,
    color: Palette.mute,
    fontVariations: _v(400, 14),
  );

  static final label = TextStyle(
    fontFamily: ui_,
    fontSize: 11,
    letterSpacing: 1.6,
    color: Palette.mute,
    fontVariations: _v(500, 14),
  );

  static final button = TextStyle(
    fontFamily: ui_,
    fontSize: 13,
    letterSpacing: 2.4,
    color: Palette.ink,
    fontVariations: _v(600, 14),
  );

  static final timer = TextStyle(
    fontFamily: ui_,
    fontSize: 12,
    letterSpacing: 0.4,
    color: Palette.mute,
    fontVariations: _v(500, 14),
  );
}

abstract final class Metrics {
  static const windowWidth = 960.0;
  static const windowHeight = 640.0;
  static const gutter = 72.0;
  static const markSize = 8.0;
  static const markGap = 7.0;
}
