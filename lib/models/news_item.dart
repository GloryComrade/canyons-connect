import '../core/utils/parsing.dart';
import 'enums.dart';

/// The Utah View content — an article or video about school activities, sports,
/// and student life.
class NewsItem {
  const NewsItem({
    required this.id,
    required this.title,
    required this.kind,
    required this.publishedAt,
    this.body,
    this.mediaUrl,
    this.externalUrl,
    this.category,
    this.author,
    this.durationSeconds,
  });

  final String id;
  final String title;
  final NewsKind kind;
  final DateTime publishedAt;
  final String? body;
  final String? mediaUrl;
  final String? externalUrl;
  final String? category;
  final String? author;

  /// For videos: runtime in seconds (for the duration badge).
  final int? durationSeconds;

  bool get isVideo => kind == NewsKind.video;

  factory NewsItem.fromMap(Map<String, dynamic> m) => NewsItem(
        id: asString(m['id']),
        title: asString(m['title'], 'Story'),
        kind: NewsKind.fromDb(asString(m['kind'], 'article')),
        publishedAt: asDate(m['published_at']),
        body: asStringOrNull(m['body']),
        mediaUrl: asStringOrNull(m['media_url']),
        externalUrl: asStringOrNull(m['external_url']),
        category: asStringOrNull(m['category']),
        author: asStringOrNull(m['author']),
        durationSeconds: m['duration_seconds'] == null ? null : asInt(m['duration_seconds']),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'kind': kind.db,
        'published_at': publishedAt.toUtc().toIso8601String(),
        'body': body,
        'media_url': mediaUrl,
        'external_url': externalUrl,
        'category': category,
        'author': author,
        'duration_seconds': durationSeconds,
      };
}
