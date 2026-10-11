import '../core/utils/parsing.dart';
import 'enums.dart';

/// The student's schedule, auto-imported from Skyward. Maps a class to a period
/// slot for a given day type. Bell *times* come from the schedule template; this
/// row supplies what class fills each period. Editable by the user.
class ClassPeriod {
  const ClassPeriod({
    required this.id,
    required this.userId,
    required this.periodLabel,
    required this.periodIndex,
    required this.className,
    this.room,
    this.teacher,
    this.dayType = DayType.regular,
    this.source = 'skyward',
    this.editedByUser = false,
  });

  final String id;
  final String userId;

  /// Display label for the period, e.g. "1", "2", "Advisory".
  final String periodLabel;

  /// Ordering index within the day.
  final int periodIndex;

  final String className;
  final String? room;
  final String? teacher;
  final DayType dayType;
  final String source;
  final bool editedByUser;

  factory ClassPeriod.fromMap(Map<String, dynamic> m) {
    return ClassPeriod(
      id: asString(m['id']),
      userId: asString(m['user_id']),
      periodLabel: asString(m['period'], '1'),
      periodIndex: asInt(m['period_index']),
      className: asString(m['class_name'], 'Class'),
      room: asStringOrNull(m['room']),
      teacher: asStringOrNull(m['teacher']),
      dayType: DayType.fromDb(asString(m['day_type'], 'regular')),
      source: asString(m['source'], 'skyward'),
      editedByUser: asBool(m['edited_by_user']),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'period': periodLabel,
        'period_index': periodIndex,
        'class_name': className,
        'room': room,
        'teacher': teacher,
        'day_type': dayType.db,
        'source': source,
        'edited_by_user': editedByUser,
      };

  ClassPeriod copyWith({
    String? className,
    String? room,
    String? teacher,
    bool? editedByUser,
  }) {
    return ClassPeriod(
      id: id,
      userId: userId,
      periodLabel: periodLabel,
      periodIndex: periodIndex,
      className: className ?? this.className,
      room: room ?? this.room,
      teacher: teacher ?? this.teacher,
      dayType: dayType,
      source: source,
      editedByUser: editedByUser ?? this.editedByUser,
    );
  }
}
