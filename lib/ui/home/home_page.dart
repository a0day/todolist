import 'package:flutter/material.dart';

import '../../application/event_controller.dart';
import '../../domain/event.dart';
import '../../domain/quadrant.dart';
import '../event/event_detail_page.dart';
import '../event/event_editor_page.dart';
import '../quadrant/quadrant_list_page.dart';
import 'quadrant_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.controller,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final EventController controller;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Set<Quadrant> _expandedCompleted = {};

  void _showError(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _toggle(Event event) async {
    try {
      await widget.controller.toggleCompleted(event);
    } catch (error) {
      _showError('更新完成状态失败：$error');
    }
  }

  Future<void> _openEvent(Event event) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) =>
            EventDetailPage(controller: widget.controller, eventId: event.id),
      ),
    );
  }

  Future<void> _addEvent(Quadrant quadrant) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => EventEditorPage(
          controller: widget.controller,
          initialQuadrant: quadrant,
        ),
      ),
    );
  }

  Future<void> _viewAll(Quadrant quadrant) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) =>
            QuadrantListPage(controller: widget.controller, quadrant: quadrant),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('四象限待办'),
        actions: [
          PopupMenuButton<ThemeMode>(
            key: const ValueKey('theme-menu'),
            tooltip: '主题',
            initialValue: widget.themeMode,
            onSelected: widget.onThemeModeChanged,
            icon: Icon(switch (widget.themeMode) {
              ThemeMode.light => Icons.light_mode_outlined,
              ThemeMode.dark => Icons.dark_mode_outlined,
              ThemeMode.system => Icons.brightness_auto_outlined,
            }),
            itemBuilder: (context) => [
              CheckedPopupMenuItem(
                value: ThemeMode.system,
                checked: widget.themeMode == ThemeMode.system,
                child: const Text('跟随系统'),
              ),
              CheckedPopupMenuItem(
                value: ThemeMode.light,
                checked: widget.themeMode == ThemeMode.light,
                child: const Text('浅色'),
              ),
              CheckedPopupMenuItem(
                value: ThemeMode.dark,
                checked: widget.themeMode == ThemeMode.dark,
                child: const Text('深色'),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) => _buildBody(context),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final controller = widget.controller;
    if (!controller.hasLoaded) {
      if (controller.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.loadError != null) {
        return _LoadFailure(
          error: controller.loadError!,
          onRetry: controller.load,
        );
      }
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 2, 10, 8),
      child: QuadrantBoard(
        q1: _buildCard(Quadrant.q1),
        q2: _buildCard(Quadrant.q2),
        q3: _buildCard(Quadrant.q3),
        q4: _buildCard(Quadrant.q4),
      ),
    );
  }

  Widget _buildCard(Quadrant quadrant) {
    final controller = widget.controller;
    return QuadrantCard(
      quadrant: quadrant,
      unfinished: controller.unfinishedIn(quadrant),
      completed: controller.completedIn(quadrant),
      completedExpanded: _expandedCompleted.contains(quadrant),
      onOpen: _openEvent,
      onToggle: _toggle,
      onViewAll: () => _viewAll(quadrant),
      onAdd: () => _addEvent(quadrant),
      onToggleCompleted: () {
        setState(() {
          if (!_expandedCompleted.remove(quadrant)) {
            _expandedCompleted.add(quadrant);
          }
        });
      },
    );
  }
}

class _LoadFailure extends StatelessWidget {
  const _LoadFailure({required this.error, required this.onRetry});

  final Object error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.storage_outlined, size: 40, color: scheme.error),
            const SizedBox(height: 12),
            Text('读取本地数据失败', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Text(
              '数据文件仍保留在设备上，不会被自动删除。',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => onRetry(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Two-by-two board with the importance axis pointing right and the urgency
/// axis pointing up. Labels are rendered exactly once, next to their arrows.
class QuadrantBoard extends StatelessWidget {
  const QuadrantBoard({
    super.key,
    required this.q1,
    required this.q2,
    required this.q3,
    required this.q4,
  });

  final Widget q1;
  final Widget q2;
  final Widget q3;
  final Widget q4;

  static const double _topBandHeight = 27;
  static const double _axisBandHeight = 29;
  static const double _columnGap = 8;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = theme.scaffoldBackgroundColor;
    final labelColor = theme.colorScheme.onSurfaceVariant;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _AxisPainter(
                    topBandHeight: _topBandHeight,
                    axisBandHeight: _axisBandHeight,
                    lineColor: theme.colorScheme.outline.withValues(
                      alpha: 0.55,
                    ),
                    arrowColor: labelColor,
                  ),
                ),
              ),
            ),
            Column(
              children: [
                const SizedBox(height: _topBandHeight),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(child: q2),
                            const SizedBox(width: _columnGap),
                            Expanded(child: q1),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: _axisBandHeight,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: _AxisLabel(
                              key: const ValueKey('axis-important'),
                              text: '重要',
                              background: background,
                              color: labelColor,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(child: q3),
                            const SizedBox(width: _columnGap),
                            Expanded(child: q4),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              top: 7,
              left: 0,
              right: 0,
              child: Center(
                child: _AxisLabel(
                  key: const ValueKey('axis-urgent'),
                  text: '紧急',
                  background: background,
                  color: labelColor,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AxisLabel extends StatelessWidget {
  const _AxisLabel({
    super.key,
    required this.text,
    required this.background,
    required this.color,
  });

  final String text;
  final Color background;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        color: background,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 10.5,
            height: 1.15,
            fontWeight: FontWeight.w600,
            color: color,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

class _AxisPainter extends CustomPainter {
  const _AxisPainter({
    required this.topBandHeight,
    required this.axisBandHeight,
    required this.lineColor,
    required this.arrowColor,
  });

  final double topBandHeight;
  final double axisBandHeight;
  final Color lineColor;
  final Color arrowColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }
    final centerX = size.width / 2;
    final gridHeight = size.height - topBandHeight;
    final rowHeight = (gridHeight - axisBandHeight) / 2;
    final axisY = topBandHeight + rowHeight + axisBandHeight / 2;

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(centerX, 0),
      Offset(centerX, size.height),
      linePaint,
    );
    canvas.drawLine(Offset(0, axisY), Offset(size.width, axisY), linePaint);

    final arrowPaint = Paint()
      ..color = arrowColor
      ..style = PaintingStyle.fill;

    final verticalArrow = Path()
      ..moveTo(centerX, 0)
      ..lineTo(centerX - 4, 6)
      ..lineTo(centerX + 4, 6)
      ..close();
    canvas.drawPath(verticalArrow, arrowPaint);

    final horizontalArrow = Path()
      ..moveTo(size.width, axisY)
      ..lineTo(size.width - 6, axisY - 4)
      ..lineTo(size.width - 6, axisY + 4)
      ..close();
    canvas.drawPath(horizontalArrow, arrowPaint);
  }

  @override
  bool shouldRepaint(_AxisPainter oldDelegate) {
    return oldDelegate.topBandHeight != topBandHeight ||
        oldDelegate.axisBandHeight != axisBandHeight ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.arrowColor != arrowColor;
  }
}

String quadrantSummary(Quadrant quadrant) => switch (quadrant) {
  Quadrant.q1 => '重要且紧急：立刻处理',
  Quadrant.q2 => '紧急但不重要：尽快处理或委托',
  Quadrant.q3 => '不重要也不紧急：暂缓或舍弃',
  Quadrant.q4 => '重要但不紧急：安排时间推进',
};
