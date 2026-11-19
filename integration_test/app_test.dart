import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:todolist/main.dart' as app;
import 'package:todolist/ui/widgets/event_tile.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('create, complete, edit and delete a schedule on device', (
    tester,
  ) async {
    app.main();
    await tester.pumpAndSettle();

    final suffix = DateTime.now().millisecondsSinceEpoch % 1000000;
    final title = '集成测试$suffix';
    final editedTitle = '$title-已编辑';

    expect(find.text('重要'), findsOneWidget);
    expect(find.text('紧急'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('quadrant-add-q4')));
    await tester.pumpAndSettle();
    expect(find.text('新建事件'), findsOneWidget);
    expect(find.text('当前归类：计划做'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('title-field')), title);
    await tester.tap(find.text('日程'));
    await tester.pumpAndSettle();
    expect(find.text('日程时间'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('start-date-button')));
    await tester.pumpAndSettle();
    expect(find.text('选择开始日期'), findsOneWidget);
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('start-time-button')));
    await tester.pumpAndSettle();
    expect(find.text('选择开始时间'), findsOneWidget);
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('save-event')));
    await tester.pumpAndSettle();

    expect(find.text(title), findsOneWidget);
    expect(find.text('日程'), findsWidgets);

    final tile = find.ancestor(
      of: find.text(title),
      matching: find.byType(EventTile),
    );
    final checkbox = find.descendant(of: tile, matching: find.byType(Checkbox));
    await tester.tap(checkbox);
    await tester.pumpAndSettle();

    final completedTitle = tester.widget<Text>(find.text(title));
    expect(completedTitle.style?.decoration, TextDecoration.lineThrough);

    await tester.tap(find.text(title));
    await tester.pumpAndSettle();
    expect(find.text('事件详情'), findsOneWidget);
    expect(find.text('已完成'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('toggle-completion')));
    await tester.pumpAndSettle();
    expect(find.text('未完成'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('edit-event')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('title-field')),
      editedTitle,
    );
    await tester.tap(find.byKey(const ValueKey('save-event')));
    await tester.pumpAndSettle();

    expect(find.text(editedTitle), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('delete-event')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-delete')));
    await tester.pumpAndSettle();

    expect(find.text('事件详情'), findsNothing);
    expect(find.text(editedTitle), findsNothing);
    expect(find.text('重要'), findsOneWidget);
  });
}
