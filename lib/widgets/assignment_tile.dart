import 'package:flutter/material.dart';

import '../core/utils/date_format.dart';
import '../design_system/ds.dart';
import '../models/models.dart';

/// A single assignment row with source/IB tags and a due-time label.
///
/// Pass [onToggle] for local checkable sources (e.g. ManageBac). For Canvas,
/// leave [onToggle] null (read-only done/todo from synced LMS status) and pass
/// [onOpenCanvas] when the assignment has a URL.
class AssignmentTile extends StatelessWidget {
  const AssignmentTile({
    super.key,
    required this.assignment,
    this.onToggle,
    this.onOpenCanvas,
    this.showDay = false,
  });

  final Assignment assignment;
  final ValueChanged<bool>? onToggle;
  final VoidCallback? onOpenCanvas;

  /// When true, prefixes the due label with the relative day (for flat lists).
  final bool showDay;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final a = assignment;
    final overdue = a.isOverdue;

    final dueLabel = showDay
        ? '${Dates.relativeDay(a.dueAt)} · ${Dates.time(a.dueAt)}'
        : Dates.time(a.dueAt);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatusIndicator(
            checked: a.isDone,
            onChanged: onToggle,
          ),
          Space.hSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.title,
                  style: AppType.bodyLarge.copyWith(
                    color: a.isDone ? c.textTertiary : c.textPrimary,
                    decoration: a.isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 2),
                Wrap(
                  spacing: Space.sm,
                  runSpacing: Space.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(a.course, style: AppType.body.copyWith(color: c.textTertiary)),
                    if (a.isIbTask)
                      const AppChip(label: 'IB', tone: ChipTone.accent),
                    AppChip(label: a.source.label, tone: ChipTone.neutral),
                  ],
                ),
                if (onOpenCanvas != null) ...[
                  const SizedBox(height: Space.xs),
                  AppButton.tertiary(
                    label: 'Open Canvas',
                    icon: Icons.open_in_new,
                    size: AppButtonSize.small,
                    onPressed: onOpenCanvas,
                  ),
                ],
              ],
            ),
          ),
          Space.hSm,
          Text(
            overdue ? 'Overdue' : dueLabel,
            style: AppType.label.copyWith(
              color: overdue ? c.danger : c.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Interactive checkbox when [onChanged] is set; otherwise a read-only done/todo mark.
class _StatusIndicator extends StatelessWidget {
  const _StatusIndicator({required this.checked, this.onChanged});
  final bool checked;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final box = Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: checked ? c.accent : Colors.transparent,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(
          color: checked ? c.accent : c.borderStrong,
          width: 1.5,
        ),
      ),
      child: checked
          ? Icon(Icons.check, size: 16, color: c.onAccent)
          : null,
    );

    if (onChanged == null) {
      return Semantics(
        checked: checked,
        label: checked ? 'Done' : 'To do',
        child: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: box,
        ),
      );
    }

    return Semantics(
      checked: checked,
      button: true,
      label: 'Mark done',
      child: InkWell(
        onTap: () => onChanged!(!checked),
        borderRadius: BorderRadius.circular(Radii.md),
        child: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: box,
        ),
      ),
    );
  }
}
