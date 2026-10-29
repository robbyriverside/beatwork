import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:beatwork/main.dart';
import 'package:beatwork/models/beat_model.dart';
import 'package:beatwork/models/story_project.dart';
import 'package:beatwork/models/story_event.dart';
import 'package:beatwork/state/story_provider.dart';
import 'package:beatwork/widgets/beat_card.dart';
import 'package:beatwork/widgets/beat_detail_dialog.dart';
import 'package:beatwork/widgets/event_dialog.dart';

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

  testWidgets('Command-E creates a story event and advances title focus', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final project = StoryProject.createSampleProject();
    await tester.pumpWidget(BeatWorkApp(initialProject: project));
    await tester.pumpAndSettle();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyE);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyE);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    await tester.pumpAndSettle();

    expect(find.text('Create Story Event'), findsOneWidget);
    final titleField = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const ValueKey('event-title-field')),
        matching: find.byType(EditableText),
      ),
    );
    expect(titleField.focusNode.hasFocus, isTrue);

    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    final descriptionField = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const ValueKey('event-description-field')),
        matching: find.byType(EditableText),
      ),
    );
    expect(descriptionField.focusNode.hasFocus, isTrue);

    await tester.enterText(
      find.byKey(const ValueKey('event-title-field')),
      'A new story event',
    );
    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    await tester.pumpAndSettle();

    expect(
      project.events.any((event) => event.title == 'A new story event'),
      isTrue,
    );
  });

  testWidgets('Command-Enter saves edits and Escape cancels event creation', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final existingEvent = StoryProject.createSampleProject().events.first;
    StoryEvent? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Column(
              children: [
                TextButton(
                  onPressed: () async {
                    result = await EventDialog.show(
                      context,
                      initialEvent: existingEvent,
                    );
                  },
                  child: const Text('Edit event'),
                ),
                TextButton(
                  onPressed: () async {
                    result = await EventDialog.show(context);
                  },
                  child: const Text('Create event'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Edit event'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('event-title-field')),
      'Updated with keyboard',
    );
    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    await tester.pumpAndSettle();

    expect(result?.title, 'Updated with keyboard');

    result = existingEvent;
    await tester.tap(find.text('Create event'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.text('Create Story Event'), findsNothing);
    expect(result, isNull);
  });

  testWidgets(
    'Command-E saves and starts another event with inherited context',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final project = StoryProject.createSampleProject();
      final existingEvent = StoryEvent(
        id: 'existing-event',
        title: 'Original event title',
        beatId: 'opening_image',
        location: 'Skyline Antenna',
        characters: ['Kael'],
      );
      project.events.add(existingEvent);
      final provider = StoryProvider(initialProject: project);
      addTearDown(provider.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  final result = await EventDialog.show(
                    context,
                    initialEvent: existingEvent,
                    onSaveAndContinue: (event, isEditing) {
                      if (isEditing) {
                        provider.updateEvent(event);
                      } else {
                        provider.createEvent(
                          title: event.title,
                          description: event.description,
                          beatId: event.beatId,
                          characters: event.characters,
                          location: event.location,
                        );
                      }
                    },
                  );
                  if (result != null) {
                    if (result.id.isEmpty) {
                      provider.createEvent(
                        title: result.title,
                        description: result.description,
                        beatId: result.beatId,
                        characters: result.characters,
                        location: result.location,
                      );
                    } else {
                      provider.updateEvent(result);
                    }
                  }
                },
                child: const Text('Open event editor'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open event editor'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('event-title-field')),
        'Updated event title',
      );
      expect(find.text('Save & New  (%E)'), findsOneWidget);
      await tester.tap(find.text('Save & New  (%E)'));
      await tester.pumpAndSettle();

      expect(find.text('Create Story Event'), findsOneWidget);
      expect(
        provider.project.events
            .singleWhere((event) => event.id == existingEvent.id)
            .title,
        'Updated event title',
      );
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('event-title-field')),
            )
            .controller!
            .text,
        isEmpty,
      );
      expect(
        tester
            .widget<EditableText>(
              find.descendant(
                of: find.byKey(const ValueKey('event-title-field')),
                matching: find.byType(EditableText),
              ),
            )
            .focusNode
            .hasFocus,
        isTrue,
      );
      expect(
        tester
            .widget<DropdownButtonFormField<String?>>(
              find.byKey(const ValueKey('event-beat-field')),
            )
            .initialValue,
        'opening_image',
      );
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('event-location-field')),
            )
            .controller!
            .text,
        'Skyline Antenna',
      );

      await tester.enterText(
        find.byKey(const ValueKey('event-title-field')),
        'Second event title',
      );
      await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyE);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyE);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
      await tester.pumpAndSettle();

      final createdEvent = project.events.singleWhere(
        (event) => event.title == 'Second event title',
      );
      expect(createdEvent.beatId, 'opening_image');
      expect(createdEvent.location, 'Skyline Antenna');
      expect(find.text('Create Story Event'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
    },
  );

  testWidgets('Command-E in Beat Edit adds the event to that beat', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final project = StoryProject.createSampleProject();
    final provider = StoryProvider(initialProject: project);
    addTearDown(provider.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => BeatDetailDialog.show(
                context,
                beat: BeatDefinition.saveTheCatBeats.first,
                provider: provider,
              ),
              child: const Text('Open Beat'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open Beat'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Events (2)'));
    await tester.pumpAndSettle();
    expect(find.text('Add Event to this Beat  (%E)'), findsOneWidget);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyE);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyE);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    await tester.pumpAndSettle();

    expect(find.text('Create Story Event'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('event-title-field')),
      'Event from beat shortcut',
    );
    await tester.tap(find.text('Create Event  (%Enter)'));
    await tester.pumpAndSettle();

    expect(
      project.events
          .singleWhere((event) => event.title == 'Event from beat shortcut')
          .beatId,
      'opening_image',
    );
  });

  testWidgets('Add Scene dialog supports title and slugline Enter navigation', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final project = StoryProject.createSampleProject();
    final provider = StoryProvider(initialProject: project);
    addTearDown(provider.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => BeatDetailDialog.show(
                context,
                beat: BeatDefinition.saveTheCatBeats.first,
                provider: provider,
              ),
              child: const Text('Open Beat for Scene'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open Beat for Scene'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add Scene to Timeline'));
    await tester.pumpAndSettle();

    final titleField = find.byKey(const ValueKey('new-scene-title-field'));
    final sluglineField = find.byKey(
      const ValueKey('new-scene-slugline-field'),
    );
    expect(
      tester
          .widget<EditableText>(
            find.descendant(
              of: titleField,
              matching: find.byType(EditableText),
            ),
          )
          .focusNode
          .hasFocus,
      isTrue,
    );

    await tester.enterText(titleField, 'A scene by keyboard');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    expect(
      tester
          .widget<EditableText>(
            find.descendant(
              of: sluglineField,
              matching: find.byType(EditableText),
            ),
          )
          .focusNode
          .hasFocus,
      isTrue,
    );

    await tester.enterText(sluglineField, 'int. archive - night');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    final scene = project.scenes.singleWhere(
      (scene) => scene.title == 'A scene by keyboard',
    );
    expect(scene.beatId, 'opening_image');
    expect(scene.activeVersion.slugline, 'INT. ARCHIVE - NIGHT');
    expect(
      tester
          .widget<EditableText>(
            find.descendant(
              of: find.byKey(const ValueKey('scene-script-body')),
              matching: find.byType(EditableText),
            ),
          )
          .focusNode
          .hasFocus,
      isTrue,
    );
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
    final actOneChipFinder = find.widgetWithText(ChoiceChip, 'Act 1');
    expect(actOneChipFinder, findsOneWidget);
    expect(find.text('Exposition & Catalyst'), findsNothing);
    final actOneChip = tester.widget<ChoiceChip>(actOneChipFinder);
    expect(actOneChip.labelStyle?.fontWeight, FontWeight.bold);
    expect(actOneChip.labelStyle?.color, StoryAct.act1.accentColor);

    // Verify Event Pool sidebar is present
    expect(find.text('Story Event Pool'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('toggle-event-pool-button')),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Hide Event Pool'));
    await tester.pumpAndSettle();
    expect(find.text('Story Event Pool'), findsNothing);
    await tester.tap(find.byTooltip('Show Event Pool'));
    await tester.pumpAndSettle();
    expect(find.text('Story Event Pool'), findsOneWidget);

    // Switch to Script Timeline
    await tester.tap(find.text('Script Timeline'));
    await tester.pumpAndSettle();

    expect(find.textContaining('SCRIPT TIMELINE'), findsOneWidget);
    expect(
      find.text('Copyright © ${DateTime.now().year} BeatWork ScriptWriter'),
      findsOneWidget,
    );
    expect(find.text('Export BeatWork'), findsOneWidget);
    expect(
      find.textContaining(
        'Summary: Tightened pacing, introduced the ticking rain',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining('Writer Notes: Latest polished version.'),
      findsOneWidget,
    );
    expect(find.textContaining('Events:'), findsWidgets);

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
