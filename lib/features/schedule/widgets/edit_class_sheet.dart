import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers.dart';
import '../../../design_system/ds.dart';
import '../../../models/models.dart';

/// Lets the student correct a class imported from Skyward (name/room/teacher)
/// as a fallback when the import is wrong.
Future<void> showEditClassSheet(BuildContext context, WidgetRef ref, ClassPeriod period) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.colors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.md)),
    ),
    builder: (_) => _EditClassSheet(period: period, ref: ref),
  );
}

class _EditClassSheet extends StatefulWidget {
  const _EditClassSheet({required this.period, required this.ref});
  final ClassPeriod period;
  final WidgetRef ref;

  @override
  State<_EditClassSheet> createState() => _EditClassSheetState();
}

class _EditClassSheetState extends State<_EditClassSheet> {
  late final _name = TextEditingController(text: widget.period.className);
  late final _room = TextEditingController(text: widget.period.room ?? '');
  late final _teacher = TextEditingController(text: widget.period.teacher ?? '');
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _room.dispose();
    _teacher.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final updated = widget.period.copyWith(
      className: _name.text.trim(),
      room: _room.text.trim(),
      teacher: _teacher.text.trim(),
      editedByUser: true,
    );
    await widget.ref.read(repositoryProvider).updateClassPeriod(updated);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(Space.md, Space.md, Space.md, Space.md + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('Edit Period ${widget.period.periodLabel}',
                  style: AppType.title.copyWith(color: c.textPrimary)),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.close, color: c.textSecondary),
              ),
            ],
          ),
          Space.vSm,
          _Field(controller: _name, label: 'Class name'),
          Space.vSm,
          _Field(controller: _room, label: 'Room'),
          Space.vSm,
          _Field(controller: _teacher, label: 'Teacher'),
          Space.vLg,
          AppButton(label: 'Save', fullWidth: true, loading: _saving, onPressed: _saving ? null : _save),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.controller, required this.label});
  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppType.label.copyWith(color: c.textSecondary)),
        Space.vXs,
        TextField(
          controller: controller,
          style: AppType.body.copyWith(color: c.textPrimary),
          decoration: InputDecoration(
            filled: true,
            fillColor: c.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.sm + 2),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Radii.md),
              borderSide: BorderSide(color: c.borderStrong),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Radii.md),
              borderSide: BorderSide(color: c.focusRing, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
