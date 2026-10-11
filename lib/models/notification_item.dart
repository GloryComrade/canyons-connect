import '../core/utils/parsing.dart';
import 'enums.dart';

/// An Inbox item aggregated from ParentSquare, GroupMe, Canvas, Skyward, the
/// School Clubs site, or school announcements. Urgent items pin to the top.
class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.userId,
    required this.source,
    required this.title,
    required this.createdAt,
    this.body,
    this.url,
    this.isUrgent = false,
    this.readAt,
    this.senderName,
  });

  final String id;
  final String userId;
  final NotificationSource source;
  final String title;
  final DateTime createdAt;
  final String? body;
  final String? url;
  final bool isUrgent;
  final DateTime? readAt;
  final String? senderName;

  bool get isRead => readAt != null;

  factory NotificationItem.fromMap(Map<String, dynamic> m) {
    return NotificationItem(
      id: asString(m['id']),
      userId: asString(m['user_id']),
      source: NotificationSource.fromDb(asString(m['source'], 'school')),
      title: asString(m['title'], 'Notification'),
      createdAt: asDate(m['created_at']),
      body: asStringOrNull(m['body']),
      url: asStringOrNull(m['url']),
      isUrgent: asBool(m['is_urgent']),
      readAt: asDateOrNull(m['read_at']),
      senderName: asStringOrNull(m['sender_name']),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'source': source.db,
        'title': title,
        'created_at': createdAt.toUtc().toIso8601String(),
        'body': body,
        'url': url,
        'is_urgent': isUrgent,
        'read_at': readAt?.toUtc().toIso8601String(),
        'sender_name': senderName,
      };

  NotificationItem copyWith({DateTime? readAt}) {
    return NotificationItem(
      id: id,
      userId: userId,
      source: source,
      title: title,
      createdAt: createdAt,
      body: body,
      url: url,
      isUrgent: isUrgent,
      readAt: readAt ?? this.readAt,
      senderName: senderName,
    );
  }
}
