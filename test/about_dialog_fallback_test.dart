import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:beatwork/main.dart';
import 'package:beatwork/models/story_project.dart';

void main() {
  testWidgets('About dialog remains available without package info plugin', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    const packageInfoChannel = MethodChannel(
      'dev.fluttercommunity.plus/package_info',
    );
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      packageInfoChannel,
      (call) async => throw MissingPluginException(),
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        packageInfoChannel,
        null,
      ),
    );

    await tester.pumpWidget(
      BeatWorkApp(initialProject: StoryProject.createSampleProject()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();

    expect(find.text('1.0.0'), findsOneWidget);
  });
}
