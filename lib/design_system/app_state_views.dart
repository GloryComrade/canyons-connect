import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/theme/dimens.dart';
import 'app_button.dart';

/// Empty state — never a blank box. Icon + title + guidance + optional action.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: EdgeInsets.all(compact ? Space.md : Space.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: compact ? 28 : 40, color: c.textTertiary),
          Space.vMd,
          Text(title, style: AppType.subtitle.copyWith(color: c.textPrimary), textAlign: TextAlign.center),
          if (message != null) ...[
            Space.vXs,
            Text(message!, style: AppType.body.copyWith(color: c.textTertiary), textAlign: TextAlign.center),
          ],
          if (actionLabel != null && onAction != null) ...[
            Space.vMd,
            AppButton.secondary(label: actionLabel!, onPressed: onAction),
          ],
        ],
      ),
    );
  }
}

/// Error state with a retry affordance.
class ErrorStateView extends StatelessWidget {
  const ErrorStateView({
    super.key,
    this.message = 'Something went wrong.',
    this.onRetry,
    this.compact = false,
  });

  final String message;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: EdgeInsets.all(compact ? Space.md : Space.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: compact ? 28 : 40, color: c.danger),
          Space.vMd,
          Text(message, style: AppType.body.copyWith(color: c.textSecondary), textAlign: TextAlign.center),
          if (onRetry != null) ...[
            Space.vMd,
            AppButton.secondary(label: 'Try again', icon: Icons.refresh, onPressed: onRetry),
          ],
        ],
      ),
    );
  }
}

/// Centered loading spinner for full-area loads (prefer skeletons for content).
class LoadingStateView extends StatelessWidget {
  const LoadingStateView({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.all(Space.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 28,
            width: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: c.accent),
          ),
          if (label != null) ...[
            Space.vMd,
            Text(label!, style: AppType.body.copyWith(color: c.textTertiary)),
          ],
        ],
      ),
    );
  }
}

/// Pulsing skeleton block used by loading placeholders.
class Skeleton extends StatefulWidget {
  const Skeleton({
    super.key,
    this.width,
    this.height = 16,
    this.radius = Radii.sm,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Color.lerp(c.skeletonBase, c.skeletonHighlight, _ctrl.value),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        );
      },
    );
  }
}

/// A few stacked skeleton rows for list placeholders.
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.rows = 3});
  final int rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < rows; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Skeleton(height: 14, width: 180),
                SizedBox(height: Space.sm),
                Skeleton(height: 12, width: 260),
              ],
            ),
          ),
      ],
    );
  }
}
