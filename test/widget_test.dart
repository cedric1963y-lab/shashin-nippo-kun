import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shashin_nippo/app_shell.dart';
import 'package:shashin_nippo/screens/photo_editor_screen.dart';

import 'support/harness.dart';

Future<void> frames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('nippo_ui_');
  });

  tearDown(() async {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  });

  testWidgets('empty home explains the first site and the free plan', (
    tester,
  ) async {
    final controller = await tester.runAsync(() => openController(directory));
    expect(controller, isNotNull);
    await tester.pumpWidget(AppShell(controller: controller!));
    await frames(tester);

    expect(find.text('現場がまだありません'), findsOneWidget);
    expect(find.textContaining('日報 0/3'), findsOneWidget);
    expect(find.textContaining('写真 0/20'), findsOneWidget);
    expect(find.textContaining('このiPhoneの中だけ'), findsOneWidget);

    await tester.tap(find.byKey(const Key('add-site')));
    await frames(tester);
    await tester.enterText(find.byKey(const Key('site-name')), '南青山リフォーム');
    await tester.enterText(find.byKey(const Key('site-note')), '元請A');
    await tester.ensureVisible(find.byKey(const Key('save-site')));
    await tester.tap(find.byKey(const Key('save-site')));
    await frames(tester);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    controller.notifyListeners();
    await tester.pump();

    expect(controller.sites.single.name, '南青山リフォーム');
    expect(find.text('南青山リフォーム'), findsOneWidget);
    expect(find.textContaining('写真 0 · 日報 0'), findsOneWidget);
    controller.dispose();
  });

  testWidgets('usage bar opens the premium explanation', (tester) async {
    final controller = await tester.runAsync(() => openController(directory));
    await tester.pumpWidget(AppShell(controller: controller!));
    await frames(tester);

    await tester.tap(find.byKey(const Key('usage-bar')));
    await frames(tester);

    expect(find.text('月額ではじめる'), findsOneWidget);
    expect(find.text('¥100'), findsWidgets);
    final scrollable = find.descendant(
      of: find.byType(ListView),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.text('年額ではじめる'),
      300,
      scrollable: scrollable,
    );
    expect(find.text('年額ではじめる'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('広告はありません'),
      300,
      scrollable: scrollable,
    );
    expect(find.text('広告はありません'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('購入を復元'),
      300,
      scrollable: scrollable,
    );
    expect(find.text('購入を復元'), findsOneWidget);
    controller.dispose();
  });

  testWidgets('photo editor keeps a memo and the capture time', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ja'),
        home: PhotoEditorScreen(
          title: '写真を追加',
          image: MemoryImage(tinyJpeg()),
          initialTakenAt: DateTime(2026, 10, 7, 9, 30),
          initialMemo: '',
          saveLabel: 'この写真を保存',
        ),
      ),
    );
    await frames(tester);

    expect(find.textContaining('2026年10月7日'), findsOneWidget);
    expect(find.textContaining('09:30'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('photo-memo')), '北側足場');
    expect(find.text('この写真を保存'), findsOneWidget);
  });
}
