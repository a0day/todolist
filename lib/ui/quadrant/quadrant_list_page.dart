import 'package:flutter/material.dart';

import '../../application/event_controller.dart';
import '../../domain/event.dart';
import '../../domain/quadrant.dart';
import '../event/event_detail_page.dart';
import '../event/event_editor_page.dart';
import '../home/home_page.dart';
import '../theme/quadrant_style.dart';
import '../widgets/event_tile.dart';

class QuadrantListPage extends StatelessWidget {
  const QuadrantListPage({
    super.key,
    required this.controller,
    required this.quadrant,
  });

  final EventController controller;
  final Quadrant quadrant;

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _add(BuildContext context) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) =>
            EventEditorPage(controller: controller, initialQuadrant: quadrant),
      ),
    );
  }

  Future<void> _open(BuildContext context, Event event) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) =>
            EventDetailPage(controller: controller, eventId: event.id),
      ),
    );
  }

  Future<void> _toggle(BuildContext context, Event event) async {
    try {
      await controller.toggleCompleted(event);
    } catch (error) {
      if (context.mounted) {
        _showError(context, '更新完成状态失败：$error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = QuadrantStyle.of(quadrant, theme.brightness);

    return Scaffold(
      appBar: AppBar(title: Text('${style.title} · 全部')),
      floatingActionButton: FloatingActionButton.extended(
        key: ValueKey('list-add-${quadrant.name}'),
        onPressed: () => _add(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('添加'),
      ),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final unfinished = controller.unfinishedIn(quadrant);
          final completed = controller.completedIn(quadrant);
          if (unfinished.isEmpty && completed.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    style.icon,
                    size: 40,
                    color: style.accent.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 10),
                  Text('这个象限还没有事件', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Text(
                    quadrantSummary(quadrant),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    key: ValueKey('list-empty-add-${quadrant.name}'),
                    onPressed: () => _add(context),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('添加事件'),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 96),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 2, 8, 10),
                child: Text(
                  quadrantSummary(quadrant),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (unfinished.isNotEmpty) ...[
                _SectionHeader(
                  label: '未完成',
                  count: unfinished.length,
                  color: style.accent,
                ),
                ...unfinished.map(
                  (event) => _ListRow(
                    child: EventTile(
                      event: event,
                      onTap: () => _open(context, event),
                      onToggle: () => _toggle(context, event),
                    ),
                  ),
                ),
              ],
              if (completed.isNotEmpty) ...[
                _SectionHeader(
                  label: '已完成',
                  count: completed.length,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                ...completed.map(
                  (event) => _ListRow(
                    child: EventTile(
                      event: event,
                      onTap: () => _open(context, event),
                      onToggle: () => _toggle(context, event),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 6),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            '$label $count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ListRow extends StatelessWidget {
  const _ListRow({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.only(left: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: child,
    );
  }
}
