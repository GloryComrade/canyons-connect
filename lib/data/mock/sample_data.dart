import '../../models/models.dart';

/// A complete, self-consistent demo dataset for Hillcrest High student
/// "Maya Ramirez" (grade 11, IB Diploma). All dates are generated relative to
/// `now` so Today / Tomorrow / This week always line up with the real clock.
class SampleDataSet {
  SampleDataSet({
    required this.profile,
    required this.classPeriods,
    required this.assignments,
    required this.grades,
    required this.events,
    required this.notifications,
    required this.newsletters,
    required this.news,
    required this.clubs,
    required this.memberships,
    required this.photoEvents,
    required this.photos,
    required this.integrations,
  });

  final Profile profile;
  final List<ClassPeriod> classPeriods;
  final List<Assignment> assignments;
  final List<Grade> grades;
  final List<CalendarEvent> events;
  final List<NotificationItem> notifications;
  final List<Newsletter> newsletters;
  final List<NewsItem> news;
  final List<Club> clubs;
  final List<ClubMembership> memberships;
  final List<PhotoEvent> photoEvents;
  final Map<String, List<Photo>> photos;
  final List<Integration> integrations;
}

class SampleData {
  const SampleData._();

  static String _img(String seed, int w, int h) =>
      'https://picsum.photos/seed/$seed/$w/$h';

  static SampleDataSet build(String userId) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime day(int add, [int h = 23, int m = 59]) =>
        today.add(Duration(days: add, hours: h, minutes: m));
    const schoolYear = '2026–2027';
    const term = 'Quarter 1';

    final profile = Profile(
      id: userId,
      name: 'Maya Ramirez',
      grade: 11,
      isIb: true,
      email: 'maya.ramirez@student.canyonsdistrict.org',
      settings: const ProfileSettings(familyAccess: true),
    );

    // --- Schedule (Skyward-imported) — regular day ---
    ClassPeriod cp(String label, int idx, String name, String room, String teacher) =>
        ClassPeriod(
          id: 'cp_$idx',
          userId: userId,
          periodLabel: label,
          periodIndex: idx,
          className: name,
          room: room,
          teacher: teacher,
        );
    final classPeriods = [
      cp('1', 0, 'AP Calculus BC', '212', 'Mr. Nguyen'),
      cp('2', 1, 'AP Chemistry', '214', 'Dr. Reyes'),
      cp('3', 2, 'AP English Lit', '108', 'Ms. Carter'),
      cp('Advisory', 3, 'Advisory', '120', 'Ms. Okafor'),
      cp('4', 4, 'US History', '231', 'Mr. Dawson'),
      cp('5', 5, 'Spanish IV', '150', 'Sra. Flores'),
      cp('6', 6, 'IB Theory of Knowledge', '118', 'Mr. Patel'),
    ];

    // --- Assignments (Canvas + ManageBac) ---
    Assignment asg(String id, AssignmentSource src, String title, String course,
            DateTime due,
            {bool ib = false, AssignmentStatus status = AssignmentStatus.todo}) =>
        Assignment(
          id: id,
          userId: userId,
          source: src,
          title: title,
          course: course,
          dueAt: due,
          isIbTask: ib,
          status: status,
        );
    final assignments = [
      asg('a_overdue', AssignmentSource.canvas, 'Problem Set 2', 'AP Calculus BC',
          day(-1, 23, 59)),
      asg('a1', AssignmentSource.canvas, 'Lab Report — Titration', 'AP Chemistry',
          day(0, 23, 59)),
      asg('a2', AssignmentSource.canvas, 'Unit 3 Problem Set', 'AP Calculus BC',
          day(1, 23, 59)),
      asg('a3', AssignmentSource.canvas, 'Reading: Chapters 12–14', 'US History',
          day(2, 23, 59)),
      asg('a4', AssignmentSource.canvas, 'Essay Draft — The Great Gatsby',
          'AP English Lit', day(3, 15, 0)),
      asg('a5', AssignmentSource.managebac, 'IA Draft — Chemistry Internal Assessment',
          'IB Chemistry', day(4, 23, 59), ib: true),
      asg('a6', AssignmentSource.managebac, 'CAS Reflection — Volunteer Hours',
          'IB CAS', day(5, 23, 59), ib: true),
      asg('a7', AssignmentSource.canvas, 'Vocabulary Quiz Prep', 'Spanish IV',
          day(6, 23, 59)),
      asg('a_done', AssignmentSource.canvas, 'Homework 7', 'AP English Lit',
          day(-2, 23, 59), status: AssignmentStatus.done),
    ];

    // --- Grades (Skyward) ---
    Grade gr(String id, String course, String letter, double pct,
            {double? prev, required DateTime updated, String? teacher}) =>
        Grade(
          id: id,
          userId: userId,
          course: course,
          term: term,
          letterGrade: letter,
          schoolYear: schoolYear,
          updatedAt: updated,
          percent: pct,
          previousPercent: prev,
          teacher: teacher,
        );
    final grades = [
      gr('g1', 'AP Calculus BC', 'A', 98, updated: day(-10, 9, 0), teacher: 'Mr. Nguyen'),
      gr('g2', 'AP Chemistry', 'B+', 88,
          prev: 85, updated: now.subtract(const Duration(hours: 3)), teacher: 'Dr. Reyes'),
      gr('g3', 'AP English Lit', 'A-', 91, updated: day(-6, 9, 0), teacher: 'Ms. Carter'),
      gr('g4', 'US History', 'A', 96,
          prev: 94, updated: now.subtract(const Duration(days: 1)), teacher: 'Mr. Dawson'),
      gr('g5', 'Spanish IV', 'B', 85, updated: day(-8, 9, 0), teacher: 'Sra. Flores'),
      gr('g6', 'IB Theory of Knowledge', 'A-', 90, updated: day(-4, 9, 0), teacher: 'Mr. Patel'),
    ];

    // --- Unified calendar events ---
    CalendarEvent ev(String id, EventSource src, String title, DateTime start,
            {String type = 'event', String? loc, DateTime? end, String? clubId}) =>
        CalendarEvent(
          id: id,
          userId: src == EventSource.schoolSite ? null : userId,
          source: src,
          title: title,
          startsAt: start,
          endsAt: end,
          type: type,
          location: loc,
          clubId: clubId,
        );
    final events = [
      ev('e1', EventSource.canvas, 'Lab Report — Titration due', day(0, 23, 59),
          type: 'assignment'),
      ev('e2', EventSource.club, 'Robotics Team meeting', day(0, 15, 30),
          type: 'club_meeting', loc: 'Rm 212 lab', clubId: 'club_robotics'),
      ev('e3', EventSource.canvas, 'Unit 3 Problem Set due', day(1, 23, 59),
          type: 'assignment'),
      ev('e4', EventSource.schoolSite, 'Early-out day', day(1, 13, 0), type: 'early_out'),
      ev('e5', EventSource.canvas, 'US History reading due', day(2, 23, 59),
          type: 'assignment'),
      ev('e6', EventSource.club, 'Ultimate Frisbee practice', day(2, 16, 0),
          type: 'club_meeting', loc: 'Lower field', clubId: 'club_frisbee'),
      ev('e7', EventSource.canvas, 'Essay Draft — Gatsby due', day(3, 15, 0),
          type: 'assignment'),
      ev('e8', EventSource.schoolSite, 'PSAT testing', day(3, 8, 0), type: 'test'),
      ev('e9', EventSource.managebac, 'IB IA Draft due', day(4, 23, 59), type: 'assignment'),
      ev('e10', EventSource.club, 'Student Council meeting', day(5, 15, 30),
          type: 'club_meeting', loc: 'Rm 120', clubId: 'club_studentcouncil'),
      ev('e11', EventSource.schoolSite, 'No school — Teacher PD', day(7, 0, 0),
          type: 'holiday'),
    ];

    // --- Inbox / notifications ---
    NotificationItem nt(String id, NotificationSource src, String title,
            DateTime created,
            {String? body, bool urgent = false, bool read = false, String? sender}) =>
        NotificationItem(
          id: id,
          userId: userId,
          source: src,
          title: title,
          createdAt: created,
          body: body,
          isUrgent: urgent,
          readAt: read ? created.add(const Duration(minutes: 5)) : null,
          senderName: sender,
        );
    final notifications = [
      nt('n1', NotificationSource.parentsquare, 'Early dismissal this Friday',
          now.subtract(const Duration(hours: 2)),
          body: 'Students will be released at 1:00 PM Friday for teacher professional development.',
          urgent: true, sender: 'Hillcrest Main Office'),
      nt('n2', NotificationSource.groupme, 'Practice moved to the gym',
          now.subtract(const Duration(hours: 1)),
          body: 'Field is wet — Robotics build session is in the gym today at 3:30.',
          sender: 'Robotics Team'),
      nt('n3', NotificationSource.skyward, 'New grade posted in AP Chemistry',
          now.subtract(const Duration(hours: 3)),
          body: 'Titration Lab Report was graded.'),
      nt('n4', NotificationSource.clubs, 'Homecoming float sign-up is open',
          now.subtract(const Duration(hours: 6)),
          body: 'Student Council needs volunteers to build the junior class float.',
          sender: 'Student Council'),
      nt('n5', NotificationSource.canvas, 'Announcement: Essay rubric posted',
          now.subtract(const Duration(hours: 8)),
          body: 'The Gatsby essay rubric is now available under Files.',
          sender: 'AP English Lit'),
      nt('n6', NotificationSource.school, 'Picture day is Thursday',
          now.subtract(const Duration(days: 1)),
          body: 'Retakes available in the auditorium during advisory.', read: true),
      nt('n7', NotificationSource.parentsquare, 'Flu shot clinic next week',
          now.subtract(const Duration(days: 2)),
          body: 'The district health team will be on campus Tuesday.', read: true,
          sender: 'Canyons Health Services'),
    ];

    // --- Newsletters ---
    final newsletters = [
      Newsletter(
        id: 'nl1',
        title: 'The Husky Weekly — Week of Oct 6',
        publishedAt: day(-2, 7, 0),
        teaser: 'Homecoming spirit week, new robotics lab opens, and fall sports standings.',
        body: 'Welcome to this week\'s edition of The Husky Weekly…',
        externalUrl: 'https://hillcrest.canyonsdistrict.org/newsletter',
      ),
      Newsletter(
        id: 'nl2',
        title: 'Counseling Center: November Course Registration',
        publishedAt: day(-9, 7, 0),
        teaser: 'Key dates and steps for registering for spring semester courses.',
        body: 'Registration opens November 1…',
      ),
    ];

    // --- The Utah View (news) ---
    final news = [
      NewsItem(
        id: 'news1',
        title: 'Inside Canyons\' new robotics lab',
        kind: NewsKind.video,
        publishedAt: now.subtract(const Duration(hours: 5)),
        category: 'STEM',
        author: 'Student Media',
        mediaUrl: _img('robolab', 800, 450),
        durationSeconds: 184,
        body: 'A look inside the newly opened robotics and engineering lab at Hillcrest.',
      ),
      NewsItem(
        id: 'news2',
        title: 'Block schedule, one year in: what\'s working',
        kind: NewsKind.article,
        publishedAt: now.subtract(const Duration(days: 1)),
        category: 'School',
        author: 'J. Alvarez',
        mediaUrl: _img('schedule', 800, 450),
        body: 'Students and teachers reflect on the first full year of block scheduling…',
      ),
      NewsItem(
        id: 'news3',
        title: 'Cedar Canyon edges Alta 21–17 in season opener',
        kind: NewsKind.article,
        publishedAt: now.subtract(const Duration(days: 2)),
        category: 'Sports',
        author: 'Husky Sports Desk',
        mediaUrl: _img('football', 800, 450),
        body: 'A late-game stop sealed the win for the Huskies…',
      ),
      NewsItem(
        id: 'news4',
        title: 'What Canyons students actually think of the IB Diploma',
        kind: NewsKind.video,
        publishedAt: now.subtract(const Duration(days: 3)),
        category: 'Academics',
        author: 'Student Media',
        mediaUrl: _img('ibdp', 800, 450),
        durationSeconds: 263,
      ),
      NewsItem(
        id: 'news5',
        title: 'Meet the seniors running "Our Town" this fall',
        kind: NewsKind.article,
        publishedAt: now.subtract(const Duration(days: 4)),
        category: 'Arts',
        author: 'A. Chen',
        mediaUrl: _img('ourtown', 800, 450),
      ),
    ];

    // --- Clubs ---
    Club club(String id, String name, String cat, String desc, String meeting,
            String coverSeed, int members, String advisor) =>
        Club(
          id: id,
          name: name,
          category: cat,
          description: desc,
          meetingInfo: meeting,
          coverUrl: _img(coverSeed, 600, 300),
          memberCount: members,
          advisor: advisor,
        );
    final clubs = [
      club('club_robotics', 'Robotics Team', 'STEM',
          'Design, build, and compete with the Hillcrest robotics team.',
          'Tue & Thu · 3:30 PM · Rm 212', 'robotics', 28, 'Dr. Reyes'),
      club('club_frisbee', 'Ultimate Frisbee', 'Sports',
          'Casual and competitive ultimate for all skill levels.',
          'Mon & Wed · 4:00 PM · Lower field', 'frisbee', 19, 'Coach Lee'),
      club('club_orange', 'Orange Club', 'Service',
          'Service projects and community volunteering across the valley.',
          'Fri · 12:45 PM · Rm 140', 'orange', 34, 'Ms. Okafor'),
      club('club_drama', 'Drama Club', 'Arts',
          'Stagecraft, acting, and the fall & spring productions.',
          'Mon–Thu · 3:30 PM · Auditorium', 'drama', 41, 'Mr. Hart'),
      club('club_studentcouncil', 'Student Council', 'Leadership',
          'Plan school events, spirit weeks, and represent the student body.',
          'Wed · 3:30 PM · Rm 120', 'council', 22, 'Ms. Okafor'),
      club('club_scioly', 'Science Olympiad', 'STEM',
          'Compete in science and engineering events across 23 disciplines.',
          'Thu · 3:30 PM · Rm 214', 'scioly', 17, 'Dr. Reyes'),
      club('club_modelun', 'Model UN', 'Academic',
          'Debate global issues and travel to conferences.',
          'Tue · 3:30 PM · Rm 231', 'modelun', 15, 'Mr. Dawson'),
      club('club_key', 'Key Club', 'Service',
          'The largest student-led service organization.',
          'Fri · 3:30 PM · Rm 108', 'keyclub', 30, 'Ms. Carter'),
    ];
    final memberships = [
      ClubMembership(userId: userId, clubId: 'club_robotics', status: MembershipStatus.joined, joinedAt: day(-30)),
      ClubMembership(userId: userId, clubId: 'club_frisbee', status: MembershipStatus.joined, joinedAt: day(-20)),
      ClubMembership(userId: userId, clubId: 'club_orange', status: MembershipStatus.joined, joinedAt: day(-15)),
      ClubMembership(userId: userId, clubId: 'club_studentcouncil', status: MembershipStatus.interested, joinedAt: day(-3)),
      ClubMembership(userId: userId, clubId: 'club_drama', status: MembershipStatus.interested, joinedAt: day(-2)),
    ];

    // --- Photo Drop ---
    PhotoEvent pe(String id, String title, String sub, DateTime start,
            String coverSeed, int photos, int contributors, {bool live = false}) =>
        PhotoEvent(
          id: id,
          title: title,
          subtitle: sub,
          startsAt: start,
          coverUrl: _img(coverSeed, 800, 450),
          photoCount: photos,
          contributorCount: contributors,
          isLive: live,
        );
    final photoEvents = [
      pe('pe1', 'Friday Night Lights vs. Corner Canyon', 'Varsity football · Home',
          day(0, 19, 0), 'fnl', 128, 42, live: true),
      pe('pe2', 'Homecoming 2026', 'Dance & spirit week', day(-7, 19, 0),
          'homecoming', 86, 30),
      pe('pe3', 'Robotics Regionals', 'Competition day', day(-14, 9, 0),
          'roboregional', 54, 12),
      pe('pe4', 'Fall Play — Our Town', 'Opening night', day(-21, 19, 0),
          'ourtownplay', 33, 9),
    ];
    final photos = <String, List<Photo>>{
      'pe1': List.generate(
        12,
        (i) => Photo(
          id: 'pe1_p$i',
          eventId: 'pe1',
          uploaderId: i.isEven ? userId : 'user_$i',
          storagePath: 'pe1/$i.jpg',
          createdAt: now.subtract(Duration(minutes: i * 7)),
          publicUrl: _img('fnl$i', 400, 400),
          uploaderName: i.isEven ? 'Maya R.' : 'Classmate $i',
        ),
      ),
      'pe2': List.generate(
        8,
        (i) => Photo(
          id: 'pe2_p$i',
          eventId: 'pe2',
          uploaderId: 'user_$i',
          storagePath: 'pe2/$i.jpg',
          createdAt: day(-7, 20, i),
          publicUrl: _img('hc$i', 400, 400),
          uploaderName: 'Classmate $i',
        ),
      ),
    };

    // --- Integrations (all linked for the demo) ---
    Integration integ(IntegrationProvider p, {IntegrationStatus status = IntegrationStatus.connected, String? detail, String? account}) =>
        Integration(
          id: 'int_${p.db}',
          userId: userId,
          provider: p,
          status: status,
          externalAccountId: account,
          lastSyncedAt: now.subtract(const Duration(minutes: 1)),
          detail: detail,
        );
    final integrations = [
      integ(IntegrationProvider.canvas, detail: '6 courses', account: 'maya.ramirez'),
      integ(IntegrationProvider.skyward, detail: 'Schedule imported · 7 classes', account: 'mramirez'),
      integ(IntegrationProvider.managebac, detail: 'IB tasks & CAS', account: 'maya.ramirez'),
      integ(IntegrationProvider.groupme, detail: '3 groups', account: 'Maya R.'),
      integ(IntegrationProvider.parentsquare, detail: 'School & class posts'),
      integ(IntegrationProvider.schoolClubs, detail: 'Rosters & meetings'),
    ];

    return SampleDataSet(
      profile: profile,
      classPeriods: classPeriods,
      assignments: assignments,
      grades: grades,
      events: events,
      notifications: notifications,
      newsletters: newsletters,
      news: news,
      clubs: clubs,
      memberships: memberships,
      photoEvents: photoEvents,
      photos: photos,
      integrations: integrations,
    );
  }
}
