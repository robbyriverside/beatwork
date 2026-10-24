import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:beatwork/main.dart';
import 'package:beatwork/models/story_project.dart';

void main() {
  testWidgets('BeatWork desktop app loads beat sheet and sample project',
      (WidgetTester tester) async {
    // Provide sample project
    final sample = StoryProject.createSampleProject();

    // Set a desktop-sized test viewport
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(BeatWorkApp(initialProject: sample));
    await tester.pumpAndSettle();

    // Verify brand title and project title are visible
    expect(find.text('BEATWORK'), findsOneWidget);
    expect(find.text('The Chronos Cipher'), findsOneWidget);

    // Verify Save the Cat header and beats
    expect(find.text('SAVE THE CAT!'), findsOneWidget);
    expect(find.text('Opening Image'), findsOneWidget);
    expect(find.text('Theme Stated'), findsOneWidget);
    expect(find.text('Set-Up'), findsOneWidget);
    expect(find.text('Catalyst'), findsOneWidget);

    // Verify Event Pool sidebar is present
    expect(find.text('Story Event Pool'), findsOneWidget);

    // Switch to Collected Script Timeline
    await tester.tap(find.text('Collected Script Timeline'));
    await tester.pumpAndSettle();

    expect(find.textContaining('COLLECTED STORY TIMELINE'), findsOneWidget);
  });
}
