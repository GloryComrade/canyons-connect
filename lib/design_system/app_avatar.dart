import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/theme/dimens.dart';

/// Identity avatar. Rounded-square (radius 4) to honor the design system's
/// no-pills / max-4px-radius rule rather than a circle. Shows an image when
/// available, else initials on an accent-subtle fill.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 40,
  });

  final String name;
  final String? imageUrl;
  final double size;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(Radii.md);
    final child = imageUrl != null && imageUrl!.isNotEmpty
        ? ClipRRect(
            borderRadius: radius,
            child: CachedNetworkImage(
              imageUrl: imageUrl!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              placeholder: (_, _) => _InitialsBox(initials: _initials, size: size),
              errorWidget: (_, _, _) => _InitialsBox(initials: _initials, size: size),
            ),
          )
        : _InitialsBox(initials: _initials, size: size);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: c.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _InitialsBox extends StatelessWidget {
  const _InitialsBox({required this.initials, required this.size});
  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: size,
      height: size,
      color: c.accentSubtle,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: AppType.label.copyWith(
          color: c.accent,
          fontSize: size * 0.36,
        ),
      ),
    );
  }
}
