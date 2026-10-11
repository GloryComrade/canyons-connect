import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../data/providers.dart';
import '../../design_system/ds.dart';

class _Result {
  const _Result(this.icon, this.title, this.subtitle, this.route);
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
}

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  String _q = '';

  List<_Result> _results() {
    final q = _q.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final out = <_Result>[];
    bool match(String s) => s.toLowerCase().contains(q);

    for (final a in ref.read(assignmentsProvider).value ?? const []) {
      if (match(a.title) || match(a.course)) {
        out.add(_Result(Icons.assignment_outlined, a.title, 'Assignment · ${a.course}', Routes.schedule));
      }
    }
    for (final g in ref.read(gradesProvider).value ?? const []) {
      if (match(g.course)) {
        out.add(_Result(Icons.bar_chart_outlined, g.course,
            'Grade · ${g.percent?.round() ?? g.letterGrade}', Routes.grades));
      }
    }
    for (final e in ref.read(eventsProvider).value ?? const []) {
      if (match(e.title)) {
        out.add(_Result(Icons.event_outlined, e.title, 'Event · ${e.source.label}', Routes.schedule));
      }
    }
    for (final n in ref.read(notificationsProvider).value ?? const []) {
      if (match(n.title) || (n.body != null && match(n.body!))) {
        out.add(_Result(Icons.inbox_outlined, n.title, 'Message · ${n.source.label}', Routes.inbox));
      }
    }
    for (final club in ref.read(clubsProvider).value ?? const []) {
      if (match(club.name) || match(club.category)) {
        out.add(_Result(Icons.groups_outlined, club.name, 'Club · ${club.category}', Routes.clubs));
      }
    }
    for (final item in ref.read(newsProvider).value ?? const []) {
      if (match(item.title)) {
        out.add(_Result(Icons.newspaper_outlined, item.title, 'Utah View', Routes.utahView));
      }
    }
    for (final pe in ref.read(photoEventsProvider).value ?? const []) {
      if (match(pe.title)) {
        out.add(_Result(Icons.photo_library_outlined, pe.title, 'Photo Drop', Routes.photoDrop));
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final results = _results();

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: Space.md),
          child: TextField(
            autofocus: true,
            style: AppType.bodyLarge.copyWith(color: c.textPrimary),
            onChanged: (v) => setState(() => _q = v),
            decoration: InputDecoration(
              hintText: 'Search assignments, grades, clubs, messages…',
              hintStyle: AppType.body.copyWith(color: c.textTertiary),
              border: InputBorder.none,
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Layout.readableWidth),
            child: _q.trim().isEmpty
                ? const EmptyState(
                    icon: Icons.search,
                    title: 'Search everything',
                    message: 'Find assignments, grades, events, messages, clubs, and photos.',
                  )
                : results.isEmpty
                    ? EmptyState(
                        icon: Icons.search_off,
                        title: 'No results',
                        message: 'Nothing matches “$_q”.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(Space.md),
                        itemCount: results.length,
                        separatorBuilder: (_, _) => Divider(height: 1, color: c.border),
                        itemBuilder: (context, i) {
                          final r = results[i];
                          return InkWell(
                            onTap: () {
                              context.go(r.route);
                            },
                            borderRadius: BorderRadius.circular(Radii.md),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: Space.md, horizontal: Space.sm),
                              child: Row(
                                children: [
                                  Icon(r.icon, size: 20, color: c.accent),
                                  Space.hMd,
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(r.title, style: AppType.bodyLarge.copyWith(color: c.textPrimary)),
                                        const SizedBox(height: 2),
                                        Text(r.subtitle, style: AppType.body.copyWith(color: c.textTertiary)),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.chevron_right, color: c.textTertiary),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ),
      ),
    );
  }
}
