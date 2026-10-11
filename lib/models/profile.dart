import '../core/utils/parsing.dart';

enum ThemeModePref {
  system,
  light,
  dark;

  String get db => name;
  static ThemeModePref fromDb(String? v) =>
      ThemeModePref.values.firstWhere((e) => e.name == v, orElse: () => ThemeModePref.system);
}

/// User preferences stored in `profiles.settings` (JSONB).
class ProfileSettings {
  const ProfileSettings({
    this.themeMode = ThemeModePref.system,
    this.pushNotifications = true,
    this.familyAccess = false,
    this.mutedSources = const [],
    this.hiddenModules = const [],
    this.moduleOrder = const [],
    this.quickActions = const [
      'schedule',
      'grades',
      'clubs',
      'photo_drop',
      'lunch_menu',
    ],
  });

  final ThemeModePref themeMode;
  final bool pushNotifications;
  final bool familyAccess;
  final List<String> mutedSources;
  final List<String> hiddenModules;
  final List<String> moduleOrder;
  final List<String> quickActions;

  factory ProfileSettings.fromMap(Map<String, dynamic> m) {
    return ProfileSettings(
      themeMode: ThemeModePref.fromDb(asStringOrNull(m['theme_mode']) ??
          (asBool(m['dark_mode']) ? 'dark' : null)),
      pushNotifications: asBool(m['push_notifications'], true),
      familyAccess: asBool(m['family_access']),
      mutedSources: asStringList(m['muted_sources']),
      hiddenModules: asStringList(m['hidden_modules']),
      moduleOrder: asStringList(m['module_order']),
      quickActions: m['quick_actions'] == null
          ? const ['schedule', 'grades', 'clubs', 'photo_drop', 'lunch_menu']
          : asStringList(m['quick_actions']),
    );
  }

  Map<String, dynamic> toMap() => {
        'theme_mode': themeMode.db,
        'dark_mode': themeMode == ThemeModePref.dark,
        'push_notifications': pushNotifications,
        'family_access': familyAccess,
        'muted_sources': mutedSources,
        'hidden_modules': hiddenModules,
        'module_order': moduleOrder,
        'quick_actions': quickActions,
      };

  ProfileSettings copyWith({
    ThemeModePref? themeMode,
    bool? pushNotifications,
    bool? familyAccess,
    List<String>? mutedSources,
    List<String>? hiddenModules,
    List<String>? moduleOrder,
    List<String>? quickActions,
  }) {
    return ProfileSettings(
      themeMode: themeMode ?? this.themeMode,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      familyAccess: familyAccess ?? this.familyAccess,
      mutedSources: mutedSources ?? this.mutedSources,
      hiddenModules: hiddenModules ?? this.hiddenModules,
      moduleOrder: moduleOrder ?? this.moduleOrder,
      quickActions: quickActions ?? this.quickActions,
    );
  }
}

/// One row per user (id → auth.users).
class Profile {
  const Profile({
    required this.id,
    required this.name,
    this.grade,
    this.isIb = false,
    this.avatarUrl,
    this.email,
    this.settings = const ProfileSettings(),
  });

  final String id;
  final String name;
  final int? grade;
  final bool isIb;
  final String? avatarUrl;
  final String? email;
  final ProfileSettings settings;

  String get firstName => name.trim().split(' ').first;

  factory Profile.fromMap(Map<String, dynamic> m) {
    return Profile(
      id: asString(m['id']),
      name: asString(m['name'], 'Student'),
      grade: m['grade'] == null ? null : asInt(m['grade']),
      isIb: asBool(m['is_ib']),
      avatarUrl: asStringOrNull(m['avatar_url'] ?? m['avatar']),
      email: asStringOrNull(m['email']),
      settings: ProfileSettings.fromMap(asMap(m['settings'])),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'grade': grade,
        'is_ib': isIb,
        'avatar_url': avatarUrl,
        'settings': settings.toMap(),
      };

  Profile copyWith({
    String? name,
    int? grade,
    bool? isIb,
    String? avatarUrl,
    String? email,
    ProfileSettings? settings,
  }) {
    return Profile(
      id: id,
      name: name ?? this.name,
      grade: grade ?? this.grade,
      isIb: isIb ?? this.isIb,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      email: email ?? this.email,
      settings: settings ?? this.settings,
    );
  }
}
