import '../core/utils/parsing.dart';

/// School-wide newsletter, surfaced in The Utah View with an archive.
class Newsletter {
  const Newsletter({
    required this.id,
    required this.title,
    required this.publishedAt,
    this.teaser,
    this.body,
    this.externalUrl,
  });

  final String id;
  final String title;
  final DateTime publishedAt;
  final String? teaser;
  final String? body;
  final String? externalUrl;

  factory Newsletter.fromMap(Map<String, dynamic> m) => Newsletter(
        id: asString(m['id']),
        title: asString(m['title'], 'Newsletter'),
        publishedAt: asDate(m['published_at']),
        teaser: asStringOrNull(m['teaser']),
        body: asStringOrNull(m['body']),
        externalUrl: asStringOrNull(m['external_url']),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'published_at': publishedAt.toUtc().toIso8601String(),
        'teaser': teaser,
        'body': body,
        'external_url': externalUrl,
      };
}
