import 'package:flutter/material.dart';

import '../../application/event_controller.dart';
import '../../core/beijing_time.dart';
import '../../domain/event.dart';
import '../theme/quadrant_style.dart';
import 'event_editor_page.dart';

class EventDetailPage extends StatelessWidget {
  const EventDetailPage({
    super.key,
    required this.controller,
    required this.eventId,
  });

  final EventController controller;
  final String eventId;

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _toggle(BuildContext context, Event event) async {
    try {
      await controller.setCompleted(event, !event.isCompleted);
    } catch (error) {
      if (context.mounted) {
        _showError(context, '更新完成状态失败：$error');
      }
    }
  }

  Future<void> _edit(BuildContext context, Event event) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => EventEditorPage(controller: controller, event: event),
      ),
    );
  }

  Future<void> _delete(BuildContext context, Event event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除事件？'),
        content: Text('确定删除“${event.title}”吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            key: const ValueKey('confirm-delete'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    try {
      await controller.delete(event);
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (context.mounted) {
        _showError(context, '删除失败：$error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final event = controller.eventById(eventId);
        return Scaffold(
          appBar: AppBar(
            title: const Text('事件详情'),
            actions: event == null
                ? null
                : [
                    IconButton(
                      key: const ValueKey('edit-event'),
                      tooltip: '编辑',
                      onPressed: () => _edit(context, event),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      key: const ValueKey('delete-event'),
                      tooltip: '删除',
                      onPressed: () => _delete(context, event),
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  ],
          ),
          body: event == null
              ? const Center(child: Text('事件不存在或已被删除'))
              : _buildBody(context, event),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, Event event) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final style = QuadrantStyle.of(event.quadrant, theme.brightness);
    final schedule = event.schedule;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        Text(
          event.title,
          key: const ValueKey('detail-title'),
          style: theme.textTheme.headlineSmall?.copyWith(
            height: 1.3,
            decoration: event.isCompleted ? TextDecoration.lineThrough : null,
            decorationColor: scheme.onSurfaceVariant,
            color: event.isCompleted ? scheme.onSurfaceVariant : null,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _Tag(label: style.title, color: style.accent, icon: style.icon),
            _Tag(
              label: eventTypeLabel(schedule != null),
              color: scheme.primary,
              icon: schedule == null
                  ? Icons.check_circle_outline_rounded
                  : Icons.event_outlined,
            ),
            _Tag(
              label: event.isCompleted ? '已完成' : '未完成',
              color: event.isCompleted
                  ? scheme.primary
                  : scheme.onSurfaceVariant,
              icon: event.isCompleted
                  ? Icons.check_rounded
                  : Icons.radio_button_unchecked_rounded,
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            children: [
              _InfoRow(
                icon: schedule == null
                    ? Icons.check_circle_outline_rounded
                    : Icons.schedule_rounded,
                label: '类型',
                value: schedule == null ? '任务' : '日程',
              ),
              _InfoRow(
                icon: Icons.flag_outlined,
                label: '重要 / 紧急',
                value:
                    '${event.important ? '重要' : '不重要'} / '
                    '${event.urgent ? '紧急' : '不紧急'}',
              ),
              if (schedule != null)
                _InfoRow(
                  icon: Icons.date_range_outlined,
                  label: '时间',
                  value:
                      BeijingTime.formatFullRange(
                        schedule.startAt,
                        schedule.endAt,
                      ) +
                      (BeijingTime.isCrossDay(schedule.startAt, schedule.endAt)
                          ? '（跨天）'
                          : ''),
                ),
              if (schedule != null && schedule.location.isNotEmpty)
                _InfoRow(
                  icon: Icons.place_outlined,
                  label: '地点',
                  value: schedule.location,
                ),
              _InfoRow(
                icon: Icons.add_circle_outline_rounded,
                label: '创建于',
                value: BeijingTime.formatChineseDateTime(event.createdAt),
              ),
              if (event.completedAt != null)
                _InfoRow(
                  icon: Icons.task_alt_rounded,
                  label: '完成于',
                  value: BeijingTime.formatChineseDateTime(event.completedAt!),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text('描述', style: theme.textTheme.titleSmall),
        const SizedBox(height: 6),
        SelectableText(
          event.description.isEmpty ? '暂无描述' : event.description,
          style: theme.textTheme.bodyMedium?.copyWith(
            height: 1.55,
            color: event.description.isEmpty
                ? scheme.onSurfaceVariant
                : scheme.onSurface,
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          key: const ValueKey('toggle-completion'),
          onPressed: () => _toggle(context, event),
          icon: Icon(
            event.isCompleted
                ? Icons.undo_rounded
                : Icons.check_circle_outline_rounded,
          ),
          label: Text(event.isCompleted ? '标记为未完成' : '标记为完成'),
        ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color, required this.icon});

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: 10),
          SizedBox(
            width: 76,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
