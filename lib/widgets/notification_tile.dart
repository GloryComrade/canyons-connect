import 'package:flutter/material.dart';

import '../core/utils/date_format.dart';
import '../design_system/ds.dart';
import '../models/models.dart';

/// A single Inbox row. Source-tagged, unread dot, urgent emphasis.
class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.item,
    this.onTap,
  });

  final NotificationItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final unread = !item.isRead;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Space.sm, horizontal: Space.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: unread ? c.accent : Colors.transparent,
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(Radii.sm),
                ),
              ),
            ),
            Space.hSm,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (item.isUrgent) ...[
                        const AppChip(label: 'Urgent', tone: ChipTone.danger),
                        Space.hXs,
                      ],
                      AppChip(label: item.source.label, tone: ChipTone.neutral),
                      const Spacer(),
                      Text(Dates.timeAgo(item.createdAt),
                          style: AppType.body.copyWith(color: c.textTertiary)),
                    ],
                  ),
                  Space.vXs,
                  Text(
                    item.title,
                    style: AppType.bodyLarge.copyWith(
                      color: c.textPrimary,
                      fontWeight: unread ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  if (item.body != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.body!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.body.copyWith(color: c.textSecondary),
                    ),
                  ],
                  if (item.senderName != null) ...[
                    const SizedBox(height: 2),
                    Text(item.senderName!,
                        style: AppType.body.copyWith(color: c.textTertiary)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
