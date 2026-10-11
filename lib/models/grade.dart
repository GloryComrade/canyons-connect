import '../core/utils/parsing.dart';

/// A Skyward grade of record for the current school year. No GPA is ever stored
/// or derived — per-class current grades only.
class Grade {
  const Grade({
    required this.id,
    required this.userId,
    required this.course,
    required this.term,
    required this.letterGrade,
    required this.schoolYear,
    required this.updatedAt,
    this.percent,
    this.previousPercent,
    this.teacher,
  });

  final String id;
  final String userId;
  final String course;
  final String term;
  final String letterGrade;
  final String schoolYear;
  final DateTime updatedAt;
  final double? percent;

  /// If present, used to show a recent-change delta chip. Not persisted as GPA.
  final double? previousPercent;
  final String? teacher;

  /// A grade is "recently changed" if updated within the last 3 days.
  bool get recentlyChanged =>
      DateTime.now().difference(updatedAt) < const Duration(days: 3);

  double? get delta =>
      (percent != null && previousPercent != null) ? percent! - previousPercent! : null;

  factory Grade.fromMap(Map<String, dynamic> m) {
    return Grade(
      id: asString(m['id']),
      userId: asString(m['user_id']),
      course: asString(m['course'], 'Course'),
      term: asString(m['term']),
      letterGrade: asString(m['grade']),
      schoolYear: asString(m['school_year']),
      updatedAt: asDate(m['updated_at']),
      percent: asDoubleOrNull(m['percent']),
      previousPercent: asDoubleOrNull(m['previous_percent']),
      teacher: asStringOrNull(m['teacher']),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'course': course,
        'term': term,
        'grade': letterGrade,
        'school_year': schoolYear,
        'updated_at': updatedAt.toUtc().toIso8601String(),
        'percent': percent,
        'teacher': teacher,
      };
}
