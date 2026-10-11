import '../core/utils/parsing.dart';
import 'enums.dart';

/// A school club/activity, backed by the School Clubs site data source.
class Club {
  const Club({
    required this.id,
    required this.name,
    required this.category,
    this.description,
    this.meetingInfo,
    this.coverUrl,
    this.memberCount,
    this.advisor,
  });

  final String id;
  final String name;
  final String category;
  final String? description;
  final String? meetingInfo;
  final String? coverUrl;
  final int? memberCount;
  final String? advisor;

  factory Club.fromMap(Map<String, dynamic> m) => Club(
        id: asString(m['id']),
        name: asString(m['name'], 'Club'),
        category: asString(m['category'], 'General'),
        description: asStringOrNull(m['description']),
        meetingInfo: asStringOrNull(m['meeting_info']),
        coverUrl: asStringOrNull(m['cover_url']),
        memberCount: m['member_count'] == null ? null : asInt(m['member_count']),
        advisor: asStringOrNull(m['advisor']),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'category': category,
        'description': description,
        'meeting_info': meetingInfo,
        'cover_url': coverUrl,
        'member_count': memberCount,
        'advisor': advisor,
      };
}

/// Join row: a user's relationship to a club.
class ClubMembership {
  const ClubMembership({
    required this.userId,
    required this.clubId,
    required this.status,
    required this.joinedAt,
  });

  final String userId;
  final String clubId;
  final MembershipStatus status;
  final DateTime joinedAt;

  factory ClubMembership.fromMap(Map<String, dynamic> m) => ClubMembership(
        userId: asString(m['user_id']),
        clubId: asString(m['club_id']),
        status: MembershipStatus.fromDb(asString(m['status'], 'interested')),
        joinedAt: asDate(m['joined_at']),
      );

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'club_id': clubId,
        'status': status.db,
        'joined_at': joinedAt.toUtc().toIso8601String(),
      };
}
