import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:beatwork/main.dart';
import 'package:beatwork/models/story_project.dart';

void main() {
  testWidgets('Command-N starts a new project from the app window', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      BeatWorkApp(initialProject: StoryProject.createSampleProject()),
    );
    await tester.pumpAndSettle();
    expect(find.text('The Chronos Cipher'), findsOneWidget);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyN);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyN);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    await tester.pumpAndSettle();

    expect(find.text('The Chronos Cipher'), findsNothing);
  });

  testWidgets('Author gear menu saves title page contact details', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final project = StoryProject.createSampleProject();
    await tester.pumpWidget(BeatWorkApp(initialProject: project));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byTooltip('Settings'));
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('System'), findsOneWidget);
    expect(find.text('Author'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
    await tester.tap(find.text('Author'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('author-name-field')),
      'Avery Writer',
    );
    await tester.enterText(
      find.byKey(const ValueKey('author-email-field')),
      'avery@example.com',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(project.author, 'Avery Writer');
    expect(project.authorEmail, 'avery@example.com');
  });

  testWidgets('saving an unchanged named project reports it is up to date', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      BeatWorkApp(
        initialProject: StoryProject.createSampleProject(),
        initialDocumentPath: '/tmp/current.beats',
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('The Chronos Cipher'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Project up to date'), findsOneWidget);
  });

  testWidgets('assigned events can be dragged between beat cards', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final project = StoryProject.createSampleProject();
    await tester.pumpWidget(BeatWorkApp(initialProject: project));
    await tester.pumpAndSettle();

    final eventTitle = 'Kael hacks a sub-orbital drone to pay back debts';
    final eventFinder = find.text(eventTitle);
    expect(eventFinder, findsOneWidget);

    await tester.drag(eventFinder, const Offset(520, 0));
    await tester.pumpAndSettle();

    expect(
      project
          .getEventsForBeat('opening_image')
          .any((event) => event.title == eventTitle),
      isFalse,
    );
    expect(
      project
          .getEventsForBeat('theme_stated')
          .any((event) => event.title == eventTitle),
      isTrue,
    );
  });

  testWidgets('BeatWork desktop app loads beat sheet and sample project', (
    WidgetTester tester,
  ) async {
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

    await tester.tap(find.text('The Chronos Cipher'));
    await tester.pumpAndSettle();
    expect(find.text('New'), findsOneWidget);
    expect(find.text('Open...'), findsOneWidget);
    expect(find.text('Save As...'), findsOneWidget);
    expect(find.text('Open Recent'), findsOneWidget);
    expect(find.text('Info'), findsNothing);
    await tester.ensureVisible(find.byTooltip('Settings'));
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('System'));
    await tester.pumpAndSettle();
    expect(find.text('System'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

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
