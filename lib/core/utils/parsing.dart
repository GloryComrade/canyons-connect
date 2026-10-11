/// Small, null-safe helpers for parsing Supabase/JSON rows into models.
library;

DateTime? asDateOrNull(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v.toLocal();
  return DateTime.tryParse(v.toString())?.toLocal();
}

DateTime asDate(dynamic v, {DateTime? fallback}) =>
    asDateOrNull(v) ?? fallback ?? DateTime.now();

String asString(dynamic v, [String fallback = '']) => v?.toString() ?? fallback;

String? asStringOrNull(dynamic v) => v?.toString();

bool asBool(dynamic v, [bool fallback = false]) {
  if (v is bool) return v;
  if (v is String) return v.toLowerCase() == 'true' || v == 't';
  if (v is num) return v != 0;
  return fallback;
}

int asInt(dynamic v, [int fallback = 0]) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? fallback;
}

double? asDoubleOrNull(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

List<String> asStringList(dynamic v) {
  if (v is List) return v.map((e) => e.toString()).toList();
  return const [];
}

Map<String, dynamic> asMap(dynamic v) {
  if (v is Map) return v.map((key, value) => MapEntry(key.toString(), value));
  return <String, dynamic>{};
}
