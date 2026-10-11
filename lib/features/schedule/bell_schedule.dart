import '../../models/models.dart';

/// A single block in the bell schedule (a class, passing period, lunch, etc.).
class BellBlock {
  const BellBlock(this.label, this.startMin, this.endMin, this.kind);
  final String label;
  final int startMin; // minutes from midnight
  final int endMin;
  final BellKind kind;

  bool get isClass => kind == BellKind.classBlock || kind == BellKind.advisory;
}

enum BellKind { classBlock, advisory, lunch, passing, breakBlock }

/// Fixed, school-defined bell templates keyed by day type. Class *content*
/// (which class fills period "2") comes from Skyward via `class_periods`; these
/// templates supply the *times*.
class BellTemplates {
  const BellTemplates._();

  static const List<BellBlock> regular = [
    BellBlock('1', 480, 530, BellKind.classBlock), // 8:00–8:50
    BellBlock('passing', 530, 535, BellKind.passing),
    BellBlock('2', 535, 585, BellKind.classBlock), // 8:55–9:45
    BellBlock('passing', 585, 590, BellKind.passing),
    BellBlock('3', 590, 640, BellKind.classBlock), // 9:50–10:40
    BellBlock('passing', 640, 645, BellKind.passing),
    BellBlock('Advisory', 645, 675, BellKind.advisory), // 10:45–11:15
    BellBlock('passing', 675, 680, BellKind.passing),
    BellBlock('4', 680, 730, BellKind.classBlock), // 11:20–12:10
    BellBlock('Lunch', 730, 765, BellKind.lunch), // 12:10–12:45
    BellBlock('passing', 765, 770, BellKind.passing),
    BellBlock('5', 770, 820, BellKind.classBlock), // 12:50–1:40
    BellBlock('passing', 820, 825, BellKind.passing),
    BellBlock('6', 825, 875, BellKind.classBlock), // 1:45–2:35
  ];

  // Early-out: compressed day ending ~1:00 PM.
  static const List<BellBlock> earlyOut = [
    BellBlock('1', 480, 515, BellKind.classBlock),
    BellBlock('passing', 515, 520, BellKind.passing),
    BellBlock('2', 520, 555, BellKind.classBlock),
    BellBlock('passing', 555, 560, BellKind.passing),
    BellBlock('3', 560, 595, BellKind.classBlock),
    BellBlock('passing', 595, 600, BellKind.passing),
    BellBlock('4', 600, 635, BellKind.classBlock),
    BellBlock('Lunch', 635, 665, BellKind.lunch),
    BellBlock('passing', 665, 670, BellKind.passing),
    BellBlock('5', 670, 705, BellKind.classBlock),
    BellBlock('passing', 705, 710, BellKind.passing),
    BellBlock('6', 710, 745, BellKind.classBlock), // ends 12:25
  ];

  // Assembly: shortened classes with an assembly block mid-morning.
  static const List<BellBlock> assembly = [
    BellBlock('1', 480, 522, BellKind.classBlock),
    BellBlock('passing', 522, 527, BellKind.passing),
    BellBlock('2', 527, 569, BellKind.classBlock),
    BellBlock('Assembly', 569, 629, BellKind.breakBlock),
    BellBlock('passing', 629, 634, BellKind.passing),
    BellBlock('3', 634, 676, BellKind.classBlock),
    BellBlock('passing', 676, 681, BellKind.passing),
    BellBlock('4', 681, 723, BellKind.classBlock),
    BellBlock('Lunch', 723, 758, BellKind.lunch),
    BellBlock('passing', 758, 763, BellKind.passing),
    BellBlock('5', 763, 805, BellKind.classBlock),
    BellBlock('passing', 805, 810, BellKind.passing),
    BellBlock('6', 810, 852, BellKind.classBlock),
  ];

  static List<BellBlock> forDay(DayType type) => switch (type) {
        DayType.earlyOut => earlyOut,
        DayType.assembly => assembly,
        DayType.finals => regular,
        _ => regular,
      };
}

enum NowPhase { beforeSchool, inClass, passing, lunch, assembly, afterSchool, noSchool }

/// A snapshot of "where in the day are we right now", ready for the Now card.
class NowCardState {
  const NowCardState({
    required this.phase,
    required this.dayType,
    this.title = '',
    this.subtitle,
    this.periodLabel,
    this.progress,
    this.remainingMinutes,
    this.nextClassName,
    this.nextRoom,
    this.minutesUntilNext,
    this.bigMessage,
  });

  final NowPhase phase;
  final DayType dayType;

  /// Headline — current class name, "Lunch", "Passing period", etc.
  final String title;
  final String? subtitle; // "Rm 214 · Dr. Reyes"
  final String? periodLabel; // "Period 2"
  final double? progress; // 0..1 through the current block
  final int? remainingMinutes;

  final String? nextClassName;
  final String? nextRoom;
  final int? minutesUntilNext;

  /// Full-width message for before/after/no-school states.
  final String? bigMessage;

  bool get hasNext => nextClassName != null && minutesUntilNext != null;
}

/// Computes the Now card state from the clock. Pure → re-run every minute.
class BellScheduleEngine {
  const BellScheduleEngine();

  NowCardState compute({
    required DateTime now,
    required DayType dayType,
    required List<ClassPeriod> periods,
  }) {
    final isWeekend = now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;
    if (isWeekend || dayType == DayType.noSchool) {
      return NowCardState(
        phase: NowPhase.noSchool,
        dayType: isWeekend ? DayType.noSchool : dayType,
        title: 'No school today',
        bigMessage: isWeekend ? 'Enjoy your weekend' : 'No classes scheduled today',
      );
    }

    final blocks = BellTemplates.forDay(dayType);
    final nowMin = now.hour * 60 + now.minute;

    ClassPeriod? classFor(String label) {
      for (final p in periods) {
        if (p.periodLabel.toLowerCase() == label.toLowerCase()) return p;
      }
      return null;
    }

    String? subtitleFor(ClassPeriod? p) {
      if (p == null) return null;
      final parts = <String>[];
      if (p.room != null && p.room!.isNotEmpty) parts.add('Rm ${p.room}');
      if (p.teacher != null && p.teacher!.isNotEmpty) parts.add(p.teacher!);
      return parts.isEmpty ? null : parts.join(' · ');
    }

    // Next upcoming class block (today).
    BellBlock? nextClassBlock;
    for (final b in blocks) {
      if (b.isClass && b.startMin > nowMin) {
        nextClassBlock = b;
        break;
      }
    }
    final nextClass = nextClassBlock == null ? null : classFor(nextClassBlock.label);
    final nextName = nextClass?.className ?? (nextClassBlock?.isClass == true ? 'Period ${nextClassBlock!.label}' : null);
    final minsUntilNext = nextClassBlock == null ? null : nextClassBlock.startMin - nowMin;

    // Before school.
    final firstBlock = blocks.first;
    if (nowMin < firstBlock.startMin) {
      final until = firstBlock.startMin - nowMin;
      return NowCardState(
        phase: NowPhase.beforeSchool,
        dayType: dayType,
        title: 'School starts soon',
        bigMessage: 'School starts in ${_dur(until)}',
        nextClassName: nextName,
        nextRoom: nextClass?.room,
        minutesUntilNext: minsUntilNext,
      );
    }

    // After school.
    final lastBlock = blocks.last;
    if (nowMin >= lastBlock.endMin) {
      final friday = now.weekday == DateTime.friday;
      return NowCardState(
        phase: NowPhase.afterSchool,
        dayType: dayType,
        title: 'Classes are done',
        bigMessage: friday ? 'Have a great weekend' : 'See you tomorrow',
      );
    }

    // Within some block.
    for (final b in blocks) {
      if (nowMin >= b.startMin && nowMin < b.endMin) {
        final progress = (nowMin - b.startMin) / (b.endMin - b.startMin);
        final remaining = b.endMin - nowMin;
        switch (b.kind) {
          case BellKind.classBlock:
          case BellKind.advisory:
            final p = classFor(b.label);
            return NowCardState(
              phase: NowPhase.inClass,
              dayType: dayType,
              title: p?.className ?? (b.kind == BellKind.advisory ? 'Advisory' : 'Period ${b.label}'),
              subtitle: subtitleFor(p),
              periodLabel: b.kind == BellKind.advisory ? 'Advisory' : 'Period ${b.label}',
              progress: progress,
              remainingMinutes: remaining,
              nextClassName: nextName,
              nextRoom: nextClass?.room,
              minutesUntilNext: minsUntilNext,
            );
          case BellKind.lunch:
            return NowCardState(
              phase: NowPhase.lunch,
              dayType: dayType,
              title: 'Lunch',
              subtitle: 'Enjoy your break',
              progress: progress,
              remainingMinutes: remaining,
              nextClassName: nextName,
              nextRoom: nextClass?.room,
              minutesUntilNext: minsUntilNext,
            );
          case BellKind.passing:
            return NowCardState(
              phase: NowPhase.passing,
              dayType: dayType,
              title: 'Passing period',
              subtitle: nextName == null ? null : 'Head to $nextName',
              progress: progress,
              remainingMinutes: remaining,
              nextClassName: nextName,
              nextRoom: nextClass?.room,
              minutesUntilNext: minsUntilNext,
            );
          case BellKind.breakBlock:
            return NowCardState(
              phase: NowPhase.assembly,
              dayType: dayType,
              title: b.label,
              progress: progress,
              remainingMinutes: remaining,
              nextClassName: nextName,
              nextRoom: nextClass?.room,
              minutesUntilNext: minsUntilNext,
            );
        }
      }
    }

    // Fallback (gaps): treat as between classes.
    return NowCardState(
      phase: NowPhase.passing,
      dayType: dayType,
      title: 'Between classes',
      nextClassName: nextName,
      nextRoom: nextClass?.room,
      minutesUntilNext: minsUntilNext,
    );
  }

  static String _dur(int minutes) {
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '$h hr' : '$h hr $m min';
  }
}

/// Determines today's day type from school-wide calendar events (+ weekend).
DayType dayTypeForToday(DateTime now, List<CalendarEvent> events) {
  if (now.weekday == DateTime.saturday || now.weekday == DateTime.sunday) {
    return DayType.noSchool;
  }
  final today = DateTime(now.year, now.month, now.day);
  for (final e in events) {
    final d = DateTime(e.startsAt.year, e.startsAt.month, e.startsAt.day);
    if (d == today) {
      switch (e.type) {
        case 'holiday':
        case 'no_school':
          return DayType.noSchool;
        case 'early_out':
          return DayType.earlyOut;
        case 'assembly':
          return DayType.assembly;
        case 'finals':
          return DayType.finals;
      }
    }
  }
  return DayType.regular;
}
