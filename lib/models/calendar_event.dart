import '../core/utils/parsing.dart';
import 'enums.dart';

/// Unified calendar item. May be personal (user_id set) or school-wide
/// (user_id null). Merges Canvas, ManageBac, the school website, and clubs.
class CalendarEvent {
  const CalendarEvent({
    required this.id,
    required this.source,
    required this.title,
    required this.startsAt,
    this.userId,
    this.endsAt,
    this.type = 'event',
    this.location,
    this.allDay = false,
    this.url,
    this.clubId,
  });

  final String id;
  final String? userId;
  final EventSource source;
  final String title;
  final DateTime startsAt;
  final DateTime? endsAt;

  /// Free-form sub-type: assignment, holiday, early_out, test, club_meeting…
  final String type;
  final String? location;
  final bool allDay;
  final String? url;
  final String? clubId;

  DateTime get day => DateTime(startsAt.year, startsAt.month, startsAt.day);

  factory CalendarEvent.fromMap(Map<String, dynamic> m) {
    return CalendarEvent(
      id: asString(m['id']),
      userId: asStringOrNull(m['user_id']),
      source: EventSource.fromDb(asString(m['source'], 'school_site')),
      title: asString(m['title'], 'Event'),
      startsAt: asDate(m['starts_at']),
      endsAt: asDateOrNull(m['ends_at']),
      type: asString(m['type'], 'event'),
      location: asStringOrNull(m['location']),
      allDay: asBool(m['all_day']),
      url: asStringOrNull(m['url']),
      clubId: asStringOrNull(m['club_id']),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'source': source.db,
        'title': title,
        'starts_at': startsAt.toUtc().toIso8601String(),
        'ends_at': endsAt?.toUtc().toIso8601String(),
        'type': type,
        'location': location,
        'all_day': allDay,
        'url': url,
        'club_id': clubId,
      };
}
