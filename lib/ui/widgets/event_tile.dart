import 'package:flutter/material.dart';

import '../../core/beijing_time.dart';
import '../../domain/event.dart';
import '../theme/quadrant_style.dart';

class EventTile extends StatelessWidget {
  const EventTile({
    super.key,
    required this.event,
    required this.onTap,
    required this.onToggle,
    this.dense = false,
  });

  final Event event;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final style = QuadrantStyle.of(event.quadrant, theme.brightness);
    final completed = event.isCompleted;
    final titleStyle = theme.textTheme.bodyMedium?.copyWith(
      fontSize: dense ? 12 : 13,
      height: 1.25,
      fontWeight: completed ? FontWeight.w400 : FontWeight.w500,
      color: completed ? scheme.onSurfaceVariant : scheme.onSurface,
      decoration: completed ? TextDecoration.lineThrough : null,
      decorationColor: scheme.onSurfaceVariant,
    );

    return Padding(
      padding: EdgeInsets.only(bottom: dense ? 1 : 3),
      child: Material(
        type: MaterialType.transparency,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              height: dense ? 38 : 44,
              child: Checkbox(
                key: ValueKey('event-checkbox-${event.id}'),
                value: completed,
                onChanged: (_) => onToggle(),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3),
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                side: BorderSide(color: scheme.outline, width: 1.4),
              ),
            ),
            Expanded(
              child: InkWell(
                key: ValueKey('event-open-${event.id}'),
                onTap: onTap,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: dense ? 4 : 6,
                    horizontal: 2,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        key: ValueKey('event-title-${event.id}'),
                        maxLines: dense ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: titleStyle,
                      ),
                      if (!dense) ...[
                        const SizedBox(height: 3),
                        _Metadata(event: event, style: style),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Metadata extends StatelessWidget {
  const _Metadata({required this.event, required this.style});

  final Event event;
  final QuadrantStyle style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final schedule = event.schedule;
    final metaColor = scheme.onSurfaceVariant;
    final metaStyle = theme.textTheme.bodySmall?.copyWith(
      fontSize: 10.5,
      height: 1.2,
      color: metaColor,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 4,
          runSpacing: 2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _TypeBadge(
              label: eventTypeLabel(schedule != null),
              color: style.accent,
              icon: schedule == null
                  ? Icons.check_circle_outline_rounded
                  : Icons.schedule_rounded,
            ),
            if (schedule != null)
              Text(
                BeijingTime.formatCardRange(schedule.startAt, schedule.endAt),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: metaStyle,
              )
            else
              Text('未设日期', style: metaStyle),
          ],
        ),
        if (schedule != null && schedule.location.isNotEmpty) ...[
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(Icons.place_outlined, size: 11, color: metaColor),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  schedule.location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: metaStyle,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              height: 1.2,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
