/// Domain enums. Each carries a `db` string that matches the Postgres enum
/// values exactly, a `fromDb` parser, and a human `label` for the UI.
library;

enum AssignmentSource {
  canvas,
  managebac;

  String get db => name;
  String get label => switch (this) {
        AssignmentSource.canvas => 'Canvas',
        AssignmentSource.managebac => 'ManageBac',
      };
  static AssignmentSource fromDb(String v) =>
      AssignmentSource.values.firstWhere((e) => e.name == v, orElse: () => AssignmentSource.canvas);
}

enum AssignmentStatus {
  todo,
  done;

  String get db => name;
  static AssignmentStatus fromDb(String v) =>
      AssignmentStatus.values.firstWhere((e) => e.name == v, orElse: () => AssignmentStatus.todo);
}

enum EventSource {
  canvas,
  managebac,
  schoolSite,
  club;

  String get db => switch (this) {
        EventSource.schoolSite => 'school_site',
        _ => name,
      };
  String get label => switch (this) {
        EventSource.canvas => 'Canvas',
        EventSource.managebac => 'ManageBac',
        EventSource.schoolSite => 'School',
        EventSource.club => 'Club',
      };
  static EventSource fromDb(String v) => switch (v) {
        'school_site' => EventSource.schoolSite,
        'canvas' => EventSource.canvas,
        'managebac' => EventSource.managebac,
        'club' => EventSource.club,
        _ => EventSource.schoolSite,
      };
}

enum NotificationSource {
  parentsquare,
  groupme,
  canvas,
  skyward,
  clubs,
  school;

  String get db => name;
  String get label => switch (this) {
        NotificationSource.parentsquare => 'ParentSquare',
        NotificationSource.groupme => 'GroupMe',
        NotificationSource.canvas => 'Canvas',
        NotificationSource.skyward => 'Skyward',
        NotificationSource.clubs => 'Clubs',
        NotificationSource.school => 'School',
      };
  static NotificationSource fromDb(String v) =>
      NotificationSource.values.firstWhere((e) => e.name == v, orElse: () => NotificationSource.school);
}

enum NewsKind {
  article,
  video;

  String get db => name;
  static NewsKind fromDb(String v) =>
      NewsKind.values.firstWhere((e) => e.name == v, orElse: () => NewsKind.article);
}

enum MembershipStatus {
  joined,
  interested;

  String get db => name;
  static MembershipStatus fromDb(String v) =>
      MembershipStatus.values.firstWhere((e) => e.name == v, orElse: () => MembershipStatus.interested);
}

enum IntegrationProvider {
  canvas,
  skyward,
  managebac,
  groupme,
  parentsquare,
  schoolClubs,
  utahView;

  String get db => switch (this) {
        IntegrationProvider.schoolClubs => 'school_clubs',
        IntegrationProvider.utahView => 'utah_view',
        _ => name,
      };

  String get label => switch (this) {
        IntegrationProvider.canvas => 'Canvas',
        IntegrationProvider.skyward => 'Skyward',
        IntegrationProvider.managebac => 'ManageBac',
        IntegrationProvider.groupme => 'GroupMe',
        IntegrationProvider.parentsquare => 'ParentSquare',
        IntegrationProvider.schoolClubs => 'School Clubs site',
        IntegrationProvider.utahView => 'The Utah View',
      };

  /// How this provider is linked, which drives the connect UI.
  bool get isOAuth =>
      this == IntegrationProvider.canvas || this == IntegrationProvider.groupme;

  static IntegrationProvider fromDb(String v) => switch (v) {
        'school_clubs' => IntegrationProvider.schoolClubs,
        'utah_view' => IntegrationProvider.utahView,
        _ => IntegrationProvider.values.firstWhere((e) => e.name == v,
            orElse: () => IntegrationProvider.canvas),
      };
}

enum IntegrationStatus {
  connected,
  notConnected,
  needsReconnect,
  syncing,
  error;

  String get db => switch (this) {
        IntegrationStatus.notConnected => 'not_connected',
        IntegrationStatus.needsReconnect => 'needs_reconnect',
        _ => name,
      };

  String get label => switch (this) {
        IntegrationStatus.connected => 'Connected',
        IntegrationStatus.notConnected => 'Not connected',
        IntegrationStatus.needsReconnect => 'Reconnect needed',
        IntegrationStatus.syncing => 'Syncing…',
        IntegrationStatus.error => 'Error',
      };

  static IntegrationStatus fromDb(String v) => switch (v) {
        'not_connected' => IntegrationStatus.notConnected,
        'needs_reconnect' => IntegrationStatus.needsReconnect,
        'connected' => IntegrationStatus.connected,
        'syncing' => IntegrationStatus.syncing,
        _ => IntegrationStatus.error,
      };
}

/// Bell-schedule day types. Drives which schedule template the Now card uses.
enum DayType {
  aDay,
  bDay,
  regular,
  assembly,
  earlyOut,
  finals,
  noSchool;

  String get db => switch (this) {
        DayType.aDay => 'a_day',
        DayType.bDay => 'b_day',
        DayType.earlyOut => 'early_out',
        DayType.noSchool => 'no_school',
        _ => name,
      };

  String get label => switch (this) {
        DayType.aDay => 'A-day',
        DayType.bDay => 'B-day',
        DayType.regular => 'Regular day',
        DayType.assembly => 'Assembly',
        DayType.earlyOut => 'Early-out',
        DayType.finals => 'Finals',
        DayType.noSchool => 'No school',
      };

  static DayType fromDb(String v) => switch (v) {
        'a_day' => DayType.aDay,
        'b_day' => DayType.bDay,
        'early_out' => DayType.earlyOut,
        'no_school' => DayType.noSchool,
        'assembly' => DayType.assembly,
        'finals' => DayType.finals,
        _ => DayType.regular,
      };
}
