import 'package:flutter/material.dart';

import '../../domain/quadrant.dart';

class QuadrantStyle {
  const QuadrantStyle({
    required this.title,
    required this.accent,
    required this.icon,
  });

  final String title;
  final Color accent;
  final IconData icon;

  static QuadrantStyle of(Quadrant quadrant, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final base = switch (quadrant) {
      Quadrant.q1 => const Color(0xFFC5533F),
      Quadrant.q2 => const Color(0xFFB57813),
      Quadrant.q3 => const Color(0xFF68758A),
      Quadrant.q4 => const Color(0xFF2C7A69),
    };
    final accent = dark ? Color.lerp(base, Colors.white, 0.28)! : base;
    return QuadrantStyle(
      title: quadrantTitle(quadrant),
      accent: accent,
      icon: switch (quadrant) {
        Quadrant.q1 => Icons.bolt_rounded,
        Quadrant.q2 => Icons.groups_2_outlined,
        Quadrant.q3 => Icons.hourglass_empty_rounded,
        Quadrant.q4 => Icons.event_available_outlined,
      },
    );
  }
}

String quadrantTitle(Quadrant quadrant) => switch (quadrant) {
  Quadrant.q1 => '立即做',
  Quadrant.q2 => '尽快做',
  Quadrant.q3 => '暂缓做',
  Quadrant.q4 => '计划做',
};

String eventTypeLabel(bool hasSchedule) => hasSchedule ? '日程' : '任务';
