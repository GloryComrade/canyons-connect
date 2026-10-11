import '../core/utils/parsing.dart';
import 'enums.dart';

/// A merged homework/IB task from Canvas or ManageBac. Local [status] lets the
/// student check items done without round-tripping to the source LMS.
class Assignment {
  const Assignment({
    required this.id,
    required this.userId,
    required this.source,
    required this.title,
    required this.course,
    required this.dueAt,
    this.externalId,
    this.status = AssignmentStatus.todo,
    this.isIbTask = false,
    this.url,
  });

  final String id;
  final String userId;
  final AssignmentSource source;
  final String title;
  final String course;
  final DateTime dueAt;
  final String? externalId;
  final AssignmentStatus status;
  final bool isIbTask;
  final String? url;

  bool get isDone => status == AssignmentStatus.done;
  bool get isOverdue => !isDone && dueAt.isBefore(DateTime.now());

  factory Assignment.fromMap(Map<String, dynamic> m) {
    return Assignment(
      id: asString(m['id']),
      userId: asString(m['user_id']),
      source: AssignmentSource.fromDb(asString(m['source'], 'canvas')),
      title: asString(m['title'], 'Assignment'),
      course: asString(m['course']),
      dueAt: asDate(m['due_at']),
      externalId: asStringOrNull(m['external_id']),
      status: AssignmentStatus.fromDb(asString(m['status'], 'todo')),
      isIbTask: asBool(m['is_ib_task']),
      url: asStringOrNull(m['url']),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'source': source.db,
        'title': title,
        'course': course,
        'due_at': dueAt.toUtc().toIso8601String(),
        'external_id': externalId,
        'status': status.db,
        'is_ib_task': isIbTask,
        'url': url,
      };

  Assignment copyWith({AssignmentStatus? status}) {
    return Assignment(
      id: id,
      userId: userId,
      source: source,
      title: title,
      course: course,
      dueAt: dueAt,
      externalId: externalId,
      status: status ?? this.status,
      isIbTask: isIbTask,
      url: url,
    );
  }
}
