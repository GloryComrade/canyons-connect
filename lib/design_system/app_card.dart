import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/dimens.dart';

/// The single approved surface container. Flat fill, 1px hairline border, 4px
/// radius, and a 0–2px elevation shadow only (never decorative). When [onTap]
/// is provided it becomes interactive with hover, focus-ring, and pressed
/// states and is keyboard-activatable.
class AppCard extends StatefulWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = Space.cardPad,
    this.semanticLabel,
    this.selected = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final String? semanticLabel;
  final bool selected;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final interactive = widget.onTap != null;

    Color borderColor = c.border;
    if (_focused) {
      borderColor = c.focusRing;
    } else if (widget.selected) {
      borderColor = c.accent;
    } else if (_hovered && interactive) {
      borderColor = c.borderStrong;
    }

    final decoration = BoxDecoration(
      color: widget.selected ? c.accentSubtle : c.surface,
      borderRadius: Radii.card,
      border: Border.all(color: borderColor, width: _focused ? 2 : 1),
      boxShadow: _hovered && interactive
          ? [BoxShadow(color: const Color(0x1A000000), blurRadius: 2, offset: const Offset(0, 1))]
          : const [BoxShadow(color: Color(0x0F000000), blurRadius: 1, offset: Offset(0, 1))],
    );

    final body = AnimatedContainer(
      duration: Motion.fast,
      curve: Motion.curve,
      decoration: decoration,
      padding: widget.padding,
      child: widget.child,
    );

    if (!interactive) {
      return Semantics(
        container: true,
        label: widget.semanticLabel,
        child: body,
      );
    }

    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
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
            child: body,
          ),
        ),
      ),
    );
  }
}
