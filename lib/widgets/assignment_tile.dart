import 'package:flutter/material.dart';

import '../core/utils/date_format.dart';
import '../design_system/ds.dart';
import '../models/models.dart';

/// A single assignment row with a local done checkbox, source/IB tags, and a
/// due-time label. Reused by Due Soon (home) and the full schedule/agenda.
class AssignmentTile extends StatelessWidget {
  const AssignmentTile({
    super.key,
    required this.assignment,
    required this.onToggle,
    this.showDay = false,
  });

  final Assignment assignment;
  final ValueChanged<bool> onToggle;

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
          _Checkbox(
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

class _Checkbox extends StatelessWidget {
  const _Checkbox({required this.checked, required this.onChanged});
  final bool checked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      checked: checked,
      button: true,
      label: 'Mark done',
      child: InkWell(
        onTap: () => onChanged(!checked),
        borderRadius: BorderRadius.circular(Radii.md),
        child: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Container(
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
          ),
        ),
      ),
    );
  }
}
