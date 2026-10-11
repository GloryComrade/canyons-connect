import '../core/utils/parsing.dart';
import 'enums.dart';

/// A connected service for a user.
///
/// SECURITY: this client-side model intentionally omits `access_token`,
/// `refresh_token`, and `encrypted_credentials`. Those columns live in Postgres
/// behind RLS/Vault and are only ever read by Edge Functions server-side. The
/// client sees connection status and sync metadata only.
class Integration {
  const Integration({
    required this.provider,
    required this.status,
    this.id,
    this.userId,
    this.externalAccountId,
    this.expiresAt,
    this.lastSyncedAt,
    this.detail,
  });

  final String? id;
  final String? userId;
  final IntegrationProvider provider;
  final IntegrationStatus status;

  /// A non-secret account handle to display, e.g. the linked email/username.
  final String? externalAccountId;
  final DateTime? expiresAt;
  final DateTime? lastSyncedAt;

  /// Optional short status detail (e.g. "Schedule imported • 7 classes").
  final String? detail;

  bool get isConnected => status == IntegrationStatus.connected;

  factory Integration.fromMap(Map<String, dynamic> m) => Integration(
        id: asStringOrNull(m['id']),
        userId: asStringOrNull(m['user_id']),
        provider: IntegrationProvider.fromDb(asString(m['provider'], 'canvas')),
        status: IntegrationStatus.fromDb(asString(m['status'], 'not_connected')),
        externalAccountId: asStringOrNull(m['external_account_id']),
        expiresAt: asDateOrNull(m['expires_at']),
        lastSyncedAt: asDateOrNull(m['last_synced_at']),
        detail: asStringOrNull(m['detail']),
      );

  /// Only non-secret fields are ever written from the client.
  Map<String, dynamic> toClientMap() => {
        'provider': provider.db,
        'status': status.db,
        'external_account_id': externalAccountId,
      };

  Integration copyWith({
    IntegrationStatus? status,
    String? externalAccountId,
    DateTime? lastSyncedAt,
    String? detail,
  }) {
    return Integration(
      id: id,
      userId: userId,
      provider: provider,
      status: status ?? this.status,
      externalAccountId: externalAccountId ?? this.externalAccountId,
      expiresAt: expiresAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      detail: detail ?? this.detail,
    );
  }
}
