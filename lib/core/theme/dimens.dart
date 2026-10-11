import 'package:flutter/widgets.dart';

/// Spacing scale — 8px base unit. Every gap/padding in the app snaps to one of
/// these. No arbitrary values (no 13px, no 17px).
///
/// 4 / 8 / 16 / 24 / 32 / 48
class Space {
  const Space._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24; // vertical rhythm between related blocks
  static const double xl = 32;
  static const double xxl = 48; // between major sections

  // Common insets, pre-built from the scale.
  static const EdgeInsets screenH = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets cardPad = EdgeInsets.all(md);
  static const SizedBox gapXs = SizedBox(height: xs, width: xs);
  static const SizedBox gapSm = SizedBox(height: sm, width: sm);
  static const SizedBox gapMd = SizedBox(height: md, width: md);
  static const SizedBox gapLg = SizedBox(height: lg, width: lg);

  static const SizedBox vXs = SizedBox(height: xs);
  static const SizedBox vSm = SizedBox(height: sm);
  static const SizedBox vMd = SizedBox(height: md);
  static const SizedBox vLg = SizedBox(height: lg);
  static const SizedBox vXl = SizedBox(height: xl);

  static const SizedBox hXs = SizedBox(width: xs);
  static const SizedBox hSm = SizedBox(width: sm);
  static const SizedBox hMd = SizedBox(width: md);
  static const SizedBox hLg = SizedBox(width: lg);
}

/// Corner radius — 4px maximum. No pills, no over-rounded cards.
class Radii {
  const Radii._();

  static const double sm = 2;
  static const double md = 4; // the ceiling

  static const BorderRadius card = BorderRadius.all(Radius.circular(md));
  static const BorderRadius control = BorderRadius.all(Radius.circular(md));
  static const BorderRadius chip = BorderRadius.all(Radius.circular(sm));
}

/// Layout constants. 12-column feel via a max content width.
class Layout {
  const Layout._();

  static const double maxContentWidth = 1200;
  static const double readableWidth = 720; // long-form reading (Utah View)
  static const double compactBreakpoint = 640;
  static const double tabletBreakpoint = 905;
}

/// Motion — restrained, functional only.
class Motion {
  const Motion._();

  static const Duration fast = Duration(milliseconds: 120);
  static const Duration normal = Duration(milliseconds: 200);
  static const Curve curve = Curves.easeInOut;
}
