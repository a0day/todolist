import 'dart:async';

import 'package:flutter/material.dart';

import '../../application/event_controller.dart';
import '../../core/beijing_time.dart';
import '../../domain/event.dart';
import '../../domain/event_conversion.dart';
import '../../domain/event_validation.dart';
import '../../domain/quadrant.dart';
import '../theme/quadrant_style.dart';

class EventEditorPage extends StatefulWidget {
  const EventEditorPage({
    super.key,
    required this.controller,
    this.event,
    this.initialQuadrant,
  });

  final EventController controller;
  final Event? event;
  final Quadrant? initialQuadrant;

  @override
  State<EventEditorPage> createState() => _EventEditorPageState();
}

class _EventEditorPageState extends State<EventEditorPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;

  late bool _important;
  late bool _urgent;
  late EventType _type;

  DateTime? _start;
  DateTime? _end;
  bool _scheduleChanged = false;
  String? _rangeError;
  bool _saving = false;

  bool get _isEditing => widget.event != null;

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    _titleController = TextEditingController(text: event?.title ?? '');
    _descriptionController = TextEditingController(
      text: event?.description ?? '',
    );
    _important =
        event?.important ?? widget.initialQuadrant?.isImportant ?? false;
    _urgent = event?.urgent ?? widget.initialQuadrant?.isUrgent ?? false;
    _type = event?.type ?? EventType.task;

    final schedule = event?.schedule;
    if (schedule != null) {
      _start = BeijingTime.wallClockFromInstant(schedule.startAt);
      _end = BeijingTime.wallClockFromInstant(schedule.endAt);
      _locationController = TextEditingController(text: schedule.location);
    } else {
      _locationController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  DateTime _toUtc(DateTime wallClock) {
    return BeijingTime.wallClockToUtc(
      year: wallClock.year,
      month: wallClock.month,
      day: wallClock.day,
      hour: wallClock.hour,
      minute: wallClock.minute,
    );
  }

  void _ensureScheduleDefaults() {
    if (_start != null && _end != null) {
      return;
    }
    final start = BeijingTime.wallClockFromInstant(
      BeijingTime.defaultStartUtc(),
    );
    _start ??= start;
    _end ??= start.add(const Duration(hours: 1));
  }

  void _handleTypeSelection(EventType type) {
    if (type == _type) {
      return;
    }
    if (type == EventType.schedule) {
      setState(() {
        _type = EventType.schedule;
        _ensureScheduleDefaults();
        _rangeError = null;
      });
      return;
    }
    unawaited(_convertToTask());
  }

  Future<void> _convertToTask() async {
    final hasScheduleData = widget.event?.schedule != null || _scheduleChanged;
    if (!hasScheduleData) {
      setState(() {
        _type = EventType.task;
        _rangeError = null;
      });
      return;
    }

    _ensureScheduleDefaults();
    final startUtc = _toUtc(_start!);
    final endUtc = _toUtc(_end!);
    final rangeError = validateScheduleRange(startUtc, endUtc);
    if (rangeError != null) {
      setState(() => _rangeError = rangeError);
      return;
    }

    final location = _locationController.text.trim();
    final summary = StringBuffer(BeijingTime.formatFullRange(startUtc, endUtc));
    if (location.isNotEmpty) {
      summary.write('，地点：$location');
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('转为任务？'),
        content: Text('日程时间和地点不会丢失，将保留到描述中：\n\n$summary'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('转为任务'),
          ),
        ],
      ),
    );
    if (!mounted) {
      return;
    }
    if (confirmed != true) {
      setState(() {});
      return;
    }

    final schedule = ScheduleDetails(
      startAt: startUtc,
      endAt: endUtc,
      location: location,
    );
    setState(() {
      _descriptionController.text = preserveScheduleInDescription(
        _descriptionController.text,
        schedule,
      );
      _type = EventType.task;
      _locationController.clear();
      _start = null;
      _end = null;
      _scheduleChanged = false;
      _rangeError = null;
    });
  }

  Future<void> _pickDate({required bool isStart}) async {
    final current = isStart ? _start : _end;
    if (current == null) {
      return;
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(current.year, current.month, current.day),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: isStart ? '选择开始日期' : '选择结束日期',
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      final updated = DateTime(
        picked.year,
        picked.month,
        picked.day,
        current.hour,
        current.minute,
      );
      if (isStart) {
        _start = updated;
      } else {
        _end = updated;
      }
      _scheduleChanged = true;
      _rangeError = null;
    });
  }

  Future<void> _pickTime({required bool isStart}) async {
    final current = isStart ? _start : _end;
    if (current == null) {
      return;
    }
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
      helpText: isStart ? '选择开始时间' : '选择结束时间',
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      final updated = DateTime(
        current.year,
        current.month,
        current.day,
        picked.hour,
        picked.minute,
      );
      if (isStart) {
        _start = updated;
      } else {
        _end = updated;
      }
      _scheduleChanged = true;
      _rangeError = null;
    });
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    ScheduleDetails? schedule;
    if (_type == EventType.schedule) {
      _ensureScheduleDefaults();
      final startUtc = _toUtc(_start!);
      final endUtc = _toUtc(_end!);
      final rangeError = validateScheduleRange(startUtc, endUtc);
      if (rangeError != null) {
        setState(() => _rangeError = rangeError);
        return;
      }
      schedule = ScheduleDetails(
        startAt: startUtc,
        endAt: endUtc,
        location: _locationController.text,
      );
    }

    setState(() {
      _saving = true;
      _rangeError = null;
    });

    try {
      final draft = EventDraft(
        title: _titleController.text,
        description: _descriptionController.text,
        important: _important,
        urgent: _urgent,
        schedule: schedule,
      );
      final existing = widget.event;
      if (existing == null) {
        await widget.controller.create(draft);
      } else {
        await widget.controller.update(existing, draft);
      }
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('保存失败：$error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final quadrant = quadrantFor(important: _important, urgent: _urgent);
    final quadrantStyle = QuadrantStyle.of(quadrant, theme.brightness);
    final crossDay =
        _type == EventType.schedule &&
        _start != null &&
        _end != null &&
        BeijingTime.isCrossDay(_toUtc(_start!), _toUtc(_end!));

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? '编辑事件' : '新建事件')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            TextFormField(
              key: const ValueKey('title-field'),
              controller: _titleController,
              autofocus: !_isEditing,
              textInputAction: TextInputAction.next,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: '标题',
                hintText: '要做什么？',
                border: OutlineInputBorder(),
              ),
              validator: validateTitle,
            ),
            const SizedBox(height: 4),
            TextFormField(
              key: const ValueKey('description-field'),
              controller: _descriptionController,
              minLines: 3,
              maxLines: 6,
              maxLength: 5000,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                labelText: '描述',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              validator: validateDescription,
            ),
            const SizedBox(height: 12),
            Text('类型', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<EventType>(
              key: const ValueKey('type-selector'),
              segments: const [
                ButtonSegment(
                  value: EventType.task,
                  label: Text('任务'),
                  icon: Icon(Icons.check_circle_outline_rounded),
                ),
                ButtonSegment(
                  value: EventType.schedule,
                  label: Text('日程'),
                  icon: Icon(Icons.event_outlined),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (selection) =>
                  _handleTypeSelection(selection.first),
            ),
            const SizedBox(height: 16),
            Text('归类', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            SwitchListTile(
              key: const ValueKey('important-switch'),
              contentPadding: EdgeInsets.zero,
              title: const Text('重要'),
              subtitle: const Text('与长期目标或核心价值相关'),
              value: _important,
              onChanged: (value) => setState(() => _important = value),
            ),
            SwitchListTile(
              key: const ValueKey('urgent-switch'),
              contentPadding: EdgeInsets.zero,
              title: const Text('紧急'),
              subtitle: const Text('需要尽快处理'),
              value: _urgent,
              onChanged: (value) => setState(() => _urgent = value),
            ),
            Container(
              margin: const EdgeInsets.only(top: 4, bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: quadrantStyle.accent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: quadrantStyle.accent.withValues(alpha: 0.30),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    quadrantStyle.icon,
                    size: 18,
                    color: quadrantStyle.accent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '当前归类：${quadrantStyle.title}',
                      key: const ValueKey('quadrant-preview'),
                      style: TextStyle(
                        color: quadrantStyle.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_type == EventType.schedule) ...[
              Text('日程时间', style: theme.textTheme.titleSmall),
              const SizedBox(height: 2),
              Text(
                '北京时间（UTC+8），24 小时制，可跨天。',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              _DateTimeField(
                label: '开始',
                wallClock: _start!,
                keyPrefix: 'start',
                onPickDate: () => _pickDate(isStart: true),
                onPickTime: () => _pickTime(isStart: true),
              ),
              const SizedBox(height: 8),
              _DateTimeField(
                label: '结束',
                wallClock: _end!,
                keyPrefix: 'end',
                onPickDate: () => _pickDate(isStart: false),
                onPickTime: () => _pickTime(isStart: false),
              ),
              if (crossDay)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.nights_stay_outlined,
                        size: 14,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '跨天日程',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              if (_rangeError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _rangeError!,
                    key: const ValueKey('range-error'),
                    style: TextStyle(color: scheme.error, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey('location-field'),
                controller: _locationController,
                maxLength: 200,
                textInputAction: TextInputAction.done,
                onChanged: (_) => _scheduleChanged = true,
                decoration: const InputDecoration(
                  labelText: '地点',
                  hintText: '可选',
                  prefixIcon: Icon(Icons.place_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: validateLocation,
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: FilledButton(
          key: const ValueKey('save-event'),
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('保存'),
        ),
      ),
    );
  }
}

class _DateTimeField extends StatelessWidget {
  const _DateTimeField({
    required this.label,
    required this.wallClock,
    required this.keyPrefix,
    required this.onPickDate,
    required this.onPickTime,
  });

  final String label;
  final DateTime wallClock;
  final String keyPrefix;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final date = '${wallClock.year}年${wallClock.month}月${wallClock.day}日';
    final time =
        '${wallClock.hour.toString().padLeft(2, '0')}:'
        '${wallClock.minute.toString().padLeft(2, '0')}';

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outline),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              label,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              key: ValueKey('$keyPrefix-date-button'),
              onTap: onPickDate,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 16,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        date,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(width: 1, height: 24, color: scheme.outlineVariant),
          Expanded(
            child: InkWell(
              key: ValueKey('$keyPrefix-time-button'),
              onTap: onPickTime,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 16,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(time),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
