import 'package:canyons_connect/app.dart';
import 'package:canyons_connect/core/utils/date_format.dart';
import 'package:canyons_connect/features/schedule/bell_schedule.dart';
import 'package:canyons_connect/models/models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ClassPeriod _cp(String label, int idx, String name) => ClassPeriod(
      id: 'cp$idx',
      userId: 'u',
      periodLabel: label,
      periodIndex: idx,
      className: name,
      room: '100',
      teacher: 'T',
    );

/// A weekday (Mon–Fri) at the given time, for deterministic schedule tests.
DateTime _weekdayAt(int h, int m) {
  var d = DateTime(2026, 10, 12, h, m); // starts on a Monday
  while (d.weekday > DateTime.friday) {
    d = d.add(const Duration(days: 1));
  }
  return d;
}

void main() {
  const engine = BellScheduleEngine();
  final periods = [
    _cp('1', 0, 'AP Calculus BC'),
    _cp('2', 1, 'AP Chemistry'),
    _cp('6', 6, 'IB Theory of Knowledge'),
  ];

  group('BellScheduleEngine', () {
    test('before school shows a countdown message', () {
      final s = engine.compute(
        now: _weekdayAt(7, 0),
        dayType: DayType.regular,
        periods: periods,
      );
      expect(s.phase, NowPhase.beforeSchool);
      expect(s.bigMessage, contains('School starts'));
    });

    test('during period 1 shows that class', () {
      final s = engine.compute(
        now: _weekdayAt(8, 30), // period 1 is 8:00–8:50
        dayType: DayType.regular,
        periods: periods,
      );
      expect(s.phase, NowPhase.inClass);
      expect(s.title, 'AP Calculus BC');
      expect(s.progress, isNotNull);
      expect(s.progress! > 0 && s.progress! < 1, isTrue);
    });

    test('after the last bell shows a done message', () {
      final s = engine.compute(
        now: _weekdayAt(16, 0), // after 2:35 PM
        dayType: DayType.regular,
        periods: periods,
      );
      expect(s.phase, NowPhase.afterSchool);
    });

    test('weekend is treated as no school', () {
      final saturday = DateTime(2026, 10, 17, 10, 0); // a Saturday
      final s = engine.compute(
        now: saturday,
        dayType: DayType.regular,
        periods: periods,
      );
      expect(s.phase, NowPhase.noSchool);
    });
  });

  group('Dates.dueGroup', () {
    final now = DateTime(2026, 10, 12, 9, 0);
    test('buckets overdue / today / tomorrow / this week', () {
      expect(Dates.dueGroup(now.subtract(const Duration(hours: 2)), from: now), 'Overdue');
      expect(Dates.dueGroup(now.add(const Duration(hours: 5)), from: now), 'Today');
      expect(Dates.dueGroup(now.add(const Duration(days: 1)), from: now), 'Tomorrow');
      expect(Dates.dueGroup(now.add(const Duration(days: 4)), from: now), 'This week');
      expect(Dates.dueGroup(now.add(const Duration(days: 20)), from: now), 'Later');
    });
  });

  testWidgets('app boots to the sign-in screen in mock mode', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: CanyonsApp()));
    await tester.pump(); // let auth state + router settle
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Canyons Connect'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
  });
}
