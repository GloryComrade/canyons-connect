import '../core/utils/parsing.dart';

/// A Photo Drop event — a scoped, event-based photo share.
class PhotoEvent {
  const PhotoEvent({
    required this.id,
    required this.title,
    required this.startsAt,
    this.coverUrl,
    this.photoCount = 0,
    this.contributorCount = 0,
    this.subtitle,
    this.isLive = false,
  });

  final String id;
  final String title;
  final DateTime startsAt;
  final String? coverUrl;
  final int photoCount;
  final int contributorCount;
  final String? subtitle;
  final bool isLive;

  factory PhotoEvent.fromMap(Map<String, dynamic> m) => PhotoEvent(
        id: asString(m['id']),
        title: asString(m['title'], 'Event'),
        startsAt: asDate(m['starts_at']),
        coverUrl: asStringOrNull(m['cover_url']),
        photoCount: asInt(m['photo_count']),
        contributorCount: asInt(m['contributor_count']),
        subtitle: asStringOrNull(m['subtitle']),
        isLive: asBool(m['is_live']),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'starts_at': startsAt.toUtc().toIso8601String(),
        'cover_url': coverUrl,
        'photo_count': photoCount,
        'contributor_count': contributorCount,
        'subtitle': subtitle,
        'is_live': isLive,
      };
}

/// A single contributed photo within a [PhotoEvent].
class Photo {
  const Photo({
    required this.id,
    required this.eventId,
    required this.uploaderId,
    required this.storagePath,
    required this.createdAt,
    this.publicUrl,
    this.caption,
    this.uploaderName,
  });

  final String id;
  final String eventId;
  final String uploaderId;
  final String storagePath;
  final DateTime createdAt;

  /// Resolved display URL (signed or public) — set by the repository.
  final String? publicUrl;
  final String? caption;
  final String? uploaderName;

  String get displayUrl => publicUrl ?? storagePath;

  factory Photo.fromMap(Map<String, dynamic> m) => Photo(
        id: asString(m['id']),
        eventId: asString(m['event_id']),
        uploaderId: asString(m['uploader_id']),
        storagePath: asString(m['storage_path']),
        createdAt: asDate(m['created_at']),
        publicUrl: asStringOrNull(m['public_url']),
        caption: asStringOrNull(m['caption']),
        uploaderName: asStringOrNull(m['uploader_name']),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'event_id': eventId,
        'uploader_id': uploaderId,
        'storage_path': storagePath,
        'created_at': createdAt.toUtc().toIso8601String(),
        'caption': caption,
      };
}
