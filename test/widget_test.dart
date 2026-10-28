import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:beatwork/main.dart';
import 'package:beatwork/models/story_project.dart';
import 'package:beatwork/widgets/beat_card.dart';

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
    expect(find.text('Project'), findsOneWidget);
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

  testWidgets('About dialog displays the macOS marketing version', (
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
      (call) async => {
        'appName': 'BeatWork',
        'packageName': 'com.example.beatwork',
        'version': '2.4.1',
        'buildNumber': '37',
        'buildSignature': '',
        'installerStore': null,
      },
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

    expect(find.text('2.4.1'), findsOneWidget);
    expect(find.text('2.4.1+37'), findsNothing);
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

    await tester.tap(find.text('BEATWORK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Project up to date'), findsOneWidget);
  });

  testWidgets('beat board starts each row after the previous row ends', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1800, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      BeatWorkApp(initialProject: StoryProject.createSampleProject()),
    );
    await tester.pumpAndSettle();

    final visibleCards = [1, 2, 3, 4].map((number) {
      final label = 'BEAT ${number.toString().padLeft(2, '0')}';
      return tester.getRect(
        find.ancestor(of: find.text(label), matching: find.byType(BeatCard)),
      );
    }).toList();
    final firstRowTop = visibleCards.first.top;
    final firstRowCards = visibleCards.where((card) => card.top == firstRowTop);
    final lastFirstRowBottom = firstRowCards.fold<double>(
      0,
      (bottom, card) => card.bottom > bottom ? card.bottom : bottom,
    );
    final beatFive = tester.getRect(
      find.ancestor(of: find.text('BEAT 05'), matching: find.byType(BeatCard)),
    );

    expect(beatFive.top, greaterThanOrEqualTo(lastFirstRowBottom));
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

  testWidgets('tapping an event in a beat opens the event editor', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final project = StoryProject.createSampleProject();
    await tester.pumpWidget(BeatWorkApp(initialProject: project));
    await tester.pumpAndSettle();

    await tester.tap(
      find.text('Kael hacks a sub-orbital drone to pay back debts'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Edit Story Event'), findsOneWidget);
    expect(find.text('BEAT 01: ACT I'), findsNothing);
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

    await tester.tap(find.byKey(const ValueKey('project-title-action')));
    await tester.pumpAndSettle();
    expect(find.text('Screenplay Title'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('BEATWORK'));
    await tester.pumpAndSettle();
    expect(find.text('New'), findsOneWidget);
    expect(find.text('Open...'), findsOneWidget);
    expect(find.text('Save As...'), findsOneWidget);
    expect(find.text('Open Recent'), findsOneWidget);
    expect(find.text('Info'), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Settings'));
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Project'));
    await tester.pumpAndSettle();
    expect(find.text('Project'), findsOneWidget);
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

    // Switch to Script Timeline
    await tester.tap(find.text('Script Timeline'));
    await tester.pumpAndSettle();

    expect(find.textContaining('SCRIPT TIMELINE'), findsOneWidget);

    final beatHeading = find.textContaining(
      'SAVE THE CAT: BEAT 1 - OPENING IMAGE',
    );
    await tester.ensureVisible(beatHeading);
    await tester.tap(beatHeading);
    await tester.pumpAndSettle();

    expect(find.text('BEAT 1: Act 1'), findsOneWidget);

    await tester.tap(find.byTooltip('Close Workspace'));
    await tester.pumpAndSettle();

    expect(find.textContaining('SCRIPT TIMELINE'), findsOneWidget);
    expect(beatHeading, findsOneWidget);
  });
}
