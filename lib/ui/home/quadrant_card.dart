import 'package:flutter/material.dart';

import '../../domain/event.dart';
import '../../domain/quadrant.dart';
import '../theme/quadrant_style.dart';
import '../widgets/event_tile.dart';

class QuadrantCard extends StatelessWidget {
  const QuadrantCard({
    super.key,
    required this.quadrant,
    required this.unfinished,
    required this.completed,
    required this.completedExpanded,
    required this.onOpen,
    required this.onToggle,
    required this.onViewAll,
    required this.onAdd,
    required this.onToggleCompleted,
  });

  final Quadrant quadrant;
  final List<Event> unfinished;
  final List<Event> completed;
  final bool completedExpanded;
  final ValueChanged<Event> onOpen;
  final ValueChanged<Event> onToggle;
  final VoidCallback onViewAll;
  final VoidCallback onAdd;
  final VoidCallback onToggleCompleted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final style = QuadrantStyle.of(quadrant, theme.brightness);
    final base = scheme.surfaceContainerLow;
    final background = Color.alphaBlend(
      style.accent.withValues(
        alpha: theme.brightness == Brightness.dark ? 0.10 : 0.06,
      ),
      base,
    );
    final alignRight = quadrant == Quadrant.q1 || quadrant == Quadrant.q4;

    return Container(
      key: ValueKey('quadrant-${quadrant.name}'),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: style.accent.withValues(alpha: 0.26),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(9, 7, 9, 3),
            child: Row(
              children: [
                Icon(style.icon, size: 14, color: style.accent),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    style.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: style.accent,
                    ),
                  ),
                ),
                _CountBadge(count: unfinished.length, color: style.accent),
              ],
            ),
          ),
          Expanded(
            child: unfinished.isEmpty && completed.isEmpty
                ? _EmptyQuadrant(accent: style.accent)
                : ListView(
                    padding: const EdgeInsets.fromLTRB(7, 2, 7, 2),
                    physics: const ClampingScrollPhysics(),
                    children: [
                      ...unfinished.map(
                        (event) => EventTile(
                          event: event,
                          onTap: () => onOpen(event),
                          onToggle: () => onToggle(event),
                        ),
                      ),
                      if (completed.isNotEmpty)
                        _CompletedSection(
                          quadrant: quadrant,
                          completed: completed,
                          expanded: completedExpanded,
                          accent: style.accent,
                          onOpen: onOpen,
                          onToggle: onToggle,
                          onToggleExpanded: onToggleCompleted,
                        ),
                    ],
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 2, 6, 6),
            child: Align(
              alignment: alignRight
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _CornerAction(
                    key: ValueKey('quadrant-all-${quadrant.name}'),
                    icon: Icons.format_list_bulleted_rounded,
                    label: '全部',
                    color: style.accent,
                    filled: false,
                    onTap: onViewAll,
                  ),
                  const SizedBox(width: 4),
                  _CornerAction(
                    key: ValueKey('quadrant-add-${quadrant.name}'),
                    icon: Icons.add_rounded,
                    label: '添加',
                    color: style.accent,
                    filled: true,
                    onTap: onAdd,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count, required this.color});

  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 18),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        '$count',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _EmptyQuadrant extends StatelessWidget {
  const _EmptyQuadrant({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 20,
              color: accent.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 2),
            Text(
              '暂无事件',
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompletedSection extends StatelessWidget {
  const _CompletedSection({
    required this.quadrant,
    required this.completed,
    required this.expanded,
    required this.accent,
    required this.onOpen,
    required this.onToggle,
    required this.onToggleExpanded,
  });

  final Quadrant quadrant;
  final List<Event> completed;
  final bool expanded;
  final Color accent;
  final ValueChanged<Event> onOpen;
  final ValueChanged<Event> onToggle;
  final VoidCallback onToggleExpanded;

  @override
  Widget build(BuildContext context) {
    final visible = expanded ? completed : completed.take(2).toList();
    final hidden = completed.length - 2;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 3),
        Row(
          children: [
            Icon(Icons.check_rounded, size: 11, color: scheme.onSurfaceVariant),
            const SizedBox(width: 2),
            Text(
              '已完成 ${completed.length}',
              style: TextStyle(
                fontSize: 9.5,
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 1),
        ...visible.map(
          (event) => EventTile(
            event: event,
            dense: true,
            onTap: () => onOpen(event),
            onToggle: () => onToggle(event),
          ),
        ),
        if (hidden > 0)
          SizedBox(
            height: 30,
            child: TextButton(
              key: ValueKey('quadrant-completed-toggle-${quadrant.name}'),
              onPressed: onToggleExpanded,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: accent,
                textStyle: const TextStyle(fontSize: 9.5),
              ),
              child: Text(expanded ? '收起' : '还有 $hidden 项已完成 · 展开'),
            ),
          ),
      ],
    );
  }
}

class _CornerAction extends StatelessWidget {
  const _CornerAction({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.filled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final showLabel = MediaQuery.textScalerOf(context).scale(10) <= 14;
    final foreground = filled ? Colors.white : color;
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        child: Material(
          color: filled ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 44,
              height: 42,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: showLabel ? 17 : 21, color: foreground),
                  if (showLabel)
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      style: TextStyle(
                        fontSize: 8.5,
                        height: 1.05,
                        color: foreground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
