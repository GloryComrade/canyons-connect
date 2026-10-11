import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/theme/dimens.dart';

/// Small label pill for tags and filters. 2px radius (not a full pill, per the
/// no-pills rule). When [onTap] is set it toggles [selected] as a filter chip
/// with hover + focus states.
class AppChip extends StatefulWidget {
  const AppChip({
    super.key,
    required this.label,
    this.onTap,
    this.selected = false,
    this.leading,
    this.tone = ChipTone.neutral,
  });

  final String label;
  final VoidCallback? onTap;
  final bool selected;
  final Widget? leading;
  final ChipTone tone;

  @override
  State<AppChip> createState() => _AppChipState();
}

enum ChipTone { neutral, danger, success, warning, accent }

class _AppChipState extends State<AppChip> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    Color fg;
    Color bg;
    Color border;

    switch (widget.tone) {
      case ChipTone.danger:
        fg = c.danger;
        bg = c.dangerSubtle;
        border = c.danger;
      case ChipTone.success:
        fg = c.success;
        bg = c.successSubtle;
        border = c.success;
      case ChipTone.warning:
        fg = c.warning;
        bg = c.warningSubtle;
        border = c.warning;
      case ChipTone.accent:
        fg = c.accent;
        bg = c.accentSubtle;
        border = c.accent;
      case ChipTone.neutral:
        fg = c.textSecondary;
        bg = c.surfaceVariant;
        border = c.border;
    }

    if (widget.selected) {
      fg = c.onAccent;
      bg = c.accent;
      border = c.accent;
    }

    if (_hovered && widget.onTap != null && !widget.selected) {
      bg = c.surfaceSelected;
    }

    final chip = AnimatedContainer(
      duration: Motion.fast,
      padding: const EdgeInsets.symmetric(horizontal: Space.sm, vertical: Space.xs),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: Radii.chip,
        border: Border.all(
          color: _focused ? c.focusRing : border.withValueAlpha(widget.tone == ChipTone.neutral ? 1 : 0.4),
          width: _focused ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.leading != null) ...[widget.leading!, Space.hXs],
          Text(widget.label, style: AppType.label.copyWith(color: fg, fontSize: 14)),
        ],
      ),
    );

    if (widget.onTap == null) return chip;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: FocusableActionDetector(
          onShowFocusHighlight: (v) => setState(() => _focused = v),
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                widget.onTap!.call();
                return null;
              },
            ),
          },
          child: Semantics(button: true, selected: widget.selected, child: chip),
        ),
      ),
    );
  }
}

extension on Color {
  Color withValueAlpha(double a) => withValues(alpha: a);
}
