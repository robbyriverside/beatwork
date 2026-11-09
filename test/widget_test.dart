import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:beatwork/main.dart';
import 'package:beatwork/models/beat_model.dart';
import 'package:beatwork/models/story_project.dart';
import 'package:beatwork/models/story_event.dart';
import 'package:beatwork/state/story_provider.dart';
import 'package:beatwork/theme/app_theme.dart';
import 'package:beatwork/widgets/beat_card.dart';
import 'package:beatwork/widgets/beat_detail_dialog.dart';
import 'package:beatwork/widgets/event_card.dart';
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

  testWidgets('beat dialog shows the page-based scene estimate', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1800, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final provider = StoryProvider(
      initialProject: StoryProject.createEmptyProject(),
    );
    addTearDown(provider.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Column(
              children: [
                for (final id in [
                  'opening_image',
                  'bad_guys_close_in',
                  'dark_night_of_the_soul',
                ])
                  TextButton(
                    onPressed: () => BeatDetailDialog.show(
                      context,
                      beat: BeatDefinition.getById(id),
                      provider: provider,
                    ),
                    child: Text(id),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('opening_image'));
    await tester.pumpAndSettle();
    expect(find.text('Estimated minimum: 1 scene.'), findsOneWidget);
    expect(
      find.textContaining('The beat timeline is the sequence'),
      findsNothing,
    );
    await tester.tap(find.text('Events (0)'));
    await tester.pumpAndSettle();
    expect(find.text('Estimated minimum: 1 event.'), findsOneWidget);
    expect(find.textContaining('Usually 3 to 5 events'), findsNothing);
    expect(find.text('No Events In This Beat Yet'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    await tester.tap(find.text('bad_guys_close_in'));
    await tester.pumpAndSettle();
    expect(find.text('Estimated minimum: 4 scenes.'), findsOneWidget);
    expect(find.text('No Scenes in Beat Timeline'), findsOneWidget);
    await tester.tap(find.text('Events (0)'));
    await tester.pumpAndSettle();
    expect(find.text('Estimated minimum: 4 events.'), findsOneWidget);

    final scenes = <String>[];
    for (var index = 0; index < 5; index++) {
      scenes.add(
        provider
            .createScene(beatId: 'bad_guys_close_in', title: 'Scene $index')
            .id,
      );
      await tester.pump();
      expect(
        find.text('Estimated minimum: ${index < 4 ? 4 : 5} events.'),
        findsOneWidget,
      );
    }

    provider.createScene(beatId: 'opening_image', title: 'Different beat');
    await tester.pump();
    expect(find.text('Estimated minimum: 5 events.'), findsOneWidget);

    provider.setSceneUnused(scenes.last, true);
    provider.deleteScene(scenes.last);
    await tester.pump();
    expect(find.text('Estimated minimum: 4 events.'), findsOneWidget);
    await tester.tap(find.text('Timeline (4)'));
    await tester.pumpAndSettle();
    expect(find.text('Estimated minimum: 4 scenes.'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    await tester.tap(find.text('dark_night_of_the_soul'));
    await tester.pumpAndSettle();
    expect(find.text('Estimated minimum: 2 scenes.'), findsOneWidget);
    await tester.tap(find.text('Events (0)'));
    await tester.pumpAndSettle();
    expect(find.text('Estimated minimum: 2 events.'), findsOneWidget);
    for (var index = 0; index < 3; index++) {
      provider.createScene(
        beatId: 'dark_night_of_the_soul',
        title: 'Ten-page beat scene $index',
      );
      await tester.pump();
      expect(
        find.text('Estimated minimum: ${index < 2 ? 2 : 3} events.'),
        findsOneWidget,
      );
    }
    await tester.tap(find.text('Timeline (3)'));
    await tester.pumpAndSettle();
    expect(find.text('Estimated minimum: 2 scenes.'), findsOneWidget);
  });

  testWidgets('estimate hints turn red below their current minimums', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1800, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final provider = StoryProvider(
      initialProject: StoryProject.createEmptyProject(),
    );
    addTearDown(provider.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => BeatDetailDialog.show(
                context,
                beat: BeatDefinition.getById('dark_night_of_the_soul'),
                provider: provider,
              ),
              child: const Text('Open Beat'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open Beat'));
    await tester.pumpAndSettle();

    Color? hintColor(String text) =>
        tester.widget<Text>(find.text(text)).style?.color;
    const sceneHint = 'Estimated minimum: 2 scenes.';
    expect(hintColor(sceneHint), AppTheme.crimsonAccent);
    final scenes = <String>[];
    for (var index = 0; index < 3; index++) {
      scenes.add(
        provider
            .createScene(
              beatId: 'dark_night_of_the_soul',
              title: 'Scene $index',
            )
            .id,
      );
      await tester.pump();
      expect(
        hintColor(sceneHint),
        index == 0 ? AppTheme.crimsonAccent : AppTheme.textSecondary,
      );
    }

    await tester.tap(find.text('Events (0)'));
    await tester.pumpAndSettle();
    const eventHint = 'Estimated minimum: 3 events.';
    expect(hintColor(eventHint), AppTheme.crimsonAccent);
    final events = <String>[];
    for (var index = 0; index < 4; index++) {
      events.add(
        provider
            .createEvent(
              beatId: 'dark_night_of_the_soul',
              title: 'Event $index',
            )
            .id,
      );
      await tester.pump();
      expect(
        hintColor(eventHint),
        index < 2 ? AppTheme.crimsonAccent : AppTheme.textSecondary,
      );
    }
    provider.unassignEvent(events.last);
    provider.deleteEvent(events.last);
    provider.unassignEvent(events[2]);
    provider.deleteEvent(events[2]);
    await tester.pump();
    expect(hintColor(eventHint), AppTheme.crimsonAccent);
    provider.setSceneUnused(scenes.last, true);
    provider.deleteScene(scenes.last);
    await tester.pump();
    expect(hintColor('Estimated minimum: 2 events.'), AppTheme.textSecondary);

    await tester.tap(find.text('Timeline (2)'));
    await tester.pumpAndSettle();
    expect(hintColor(sceneHint), AppTheme.textSecondary);
    provider.setSceneUnused(scenes.first, true);
    provider.deleteScene(scenes.first);
    await tester.pump();
    expect(hintColor(sceneHint), AppTheme.crimsonAccent);
  });

  testWidgets(
    'unused scenes can be hidden, restored, and deleted with confirmation',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());
      final project = StoryProject.createEmptyProject();
      final provider = StoryProvider(initialProject: project);
      addTearDown(provider.dispose);
      final first = provider.createScene(
        beatId: 'opening_image',
        title: 'First scene',
      );
      final second = provider.createScene(
        beatId: 'opening_image',
        title: 'Second scene',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => BeatDetailDialog.show(
                  context,
                  beat: BeatDefinition.getById('opening_image'),
                  provider: provider,
                ),
                child: const Text('Open Beat'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open Beat'));
      await tester.pumpAndSettle();
      Finder sceneMenu(String id) => find.descendant(
        of: find.byKey(ValueKey(id)),
        matching: find.byType(PopupMenuButton<String>),
      );
      await tester.tap(sceneMenu(first.id));
      await tester.pumpAndSettle();
      expect(find.text('Delete Scene'), findsNothing);
      await tester.tap(find.text('Mark as Unused'));
      await tester.pumpAndSettle();
      expect(first.isUnused, isTrue);
      expect(find.text('UNUSED'), findsOneWidget);
      expect(
        tester.getTopLeft(find.byKey(ValueKey(second.id))).dy,
        lessThan(tester.getTopLeft(find.byKey(ValueKey(first.id))).dy),
      );
      expect(project.getCollectedTimeline().map((entry) => entry.scene.id), [
        second.id,
      ]);

      await tester.tap(find.text('Hide unused scenes'));
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey(first.id)), findsNothing);
      await tester.tap(find.text('Show unused scenes'));
      await tester.pumpAndSettle();
      await tester.tap(sceneMenu(first.id));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mark as Used'));
      await tester.pumpAndSettle();
      expect(first.isUnused, isFalse);
      expect(project.getCollectedTimeline().length, 2);

      await tester.tap(sceneMenu(first.id));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mark as Unused'));
      await tester.pumpAndSettle();
      await tester.tap(sceneMenu(first.id));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete Scene'));
      await tester.pumpAndSettle();
      expect(find.text('Delete Scene?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(project.scenes, contains(first));
      await tester.tap(sceneMenu(first.id));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete Scene'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete Scene'));
      await tester.pumpAndSettle();
      expect(project.scenes, isNot(contains(first)));
    },
  );

  testWidgets('scene handles reorder within top and bottom sections', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1800, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    final provider = StoryProvider(
      initialProject: StoryProject.createEmptyProject(),
    );
    addTearDown(provider.dispose);
    final scenes = List.generate(
      4,
      (index) =>
          provider.createScene(beatId: 'opening_image', title: 'Scene $index'),
    );
    provider.setSceneUnused(scenes[2].id, true);
    provider.setSceneUnused(scenes[3].id, true);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => BeatDetailDialog.show(
                context,
                beat: BeatDefinition.getById('opening_image'),
                provider: provider,
              ),
              child: const Text('Open Beat'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open Beat'));
    await tester.pumpAndSettle();

    Finder item(int index) => find.byKey(ValueKey(scenes[index].id));
    Finder handle(int index) => find.descendant(
      of: item(index),
      matching: find.byType(ReorderableDragStartListener),
    );
    Finder menu(int index) => find.descendant(
      of: item(index),
      matching: find.byType(PopupMenuButton<String>),
    );
    final topList = find.byKey(const ValueKey('active-scenes-list'));
    final bottomList = find.byKey(const ValueKey('unused-scenes-list'));
    expect(tester.widget<ReorderableListView>(topList).shrinkWrap, isFalse);
    expect(tester.widget<ReorderableListView>(bottomList).shrinkWrap, isFalse);
    expect(
      tester.getTopLeft(handle(0)).dx,
      lessThan(tester.getTopLeft(menu(0)).dx),
    );
    expect(
      tester.getTopLeft(item(0)).dy - tester.getTopLeft(topList).dy,
      lessThan(10),
    );
    expect(
      tester.getBottomLeft(bottomList).dy - tester.getBottomLeft(item(3)).dy,
      lessThan(15),
    );
    expect(
      tester.getTopLeft(item(2)).dy - tester.getBottomLeft(item(1)).dy,
      greaterThan(20),
    );

    final activeDrag = await tester.startGesture(tester.getCenter(handle(0)));
    await tester.pump();
    await activeDrag.moveBy(const Offset(0, 20));
    await tester.pump();
    await activeDrag.moveBy(const Offset(0, 180));
    await tester.pump(const Duration(milliseconds: 400));
    await activeDrag.up();
    await tester.pumpAndSettle();
    expect(
      provider.project
          .getScenesForBeat('opening_image')
          .map((scene) => scene.id),
      [scenes[1].id, scenes[0].id, scenes[2].id, scenes[3].id],
    );

    final unusedDrag = await tester.startGesture(tester.getCenter(handle(2)));
    await tester.pump();
    await unusedDrag.moveBy(const Offset(0, 20));
    await tester.pump();
    await unusedDrag.moveBy(const Offset(0, 180));
    await tester.pump(const Duration(milliseconds: 400));
    await unusedDrag.up();
    await tester.pumpAndSettle();
    expect(
      provider.project
          .getScenesForBeat('opening_image')
          .map((scene) => scene.id),
      [scenes[1].id, scenes[0].id, scenes[3].id, scenes[2].id],
    );

    for (var index = 0; index < 8; index++) {
      final scene = provider.createScene(
        beatId: 'opening_image',
        title: 'Extra unused $index',
      );
      provider.setSceneUnused(scene.id, true);
    }
    await tester.pumpAndSettle();
    final bottomPosition = tester
        .state<ScrollableState>(
          find
              .descendant(of: bottomList, matching: find.byType(Scrollable))
              .first,
        )
        .position;
    expect(bottomPosition.maxScrollExtent, greaterThan(0));
    await tester.sendEventToBinding(
      PointerScrollEvent(
        position: tester.getCenter(bottomList),
        scrollDelta: const Offset(0, 2000),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find
          .descendant(of: bottomList, matching: find.text('Extra unused 7'))
          .hitTestable(),
      findsOneWidget,
    );
    expect(find.byKey(ValueKey(scenes[1].id)).hitTestable(), findsOneWidget);

    final reorderWithUnused = await tester.startGesture(
      tester.getCenter(handle(1)),
    );
    await tester.pump();
    await reorderWithUnused.moveBy(const Offset(0, 20));
    await tester.pump();
    await reorderWithUnused.moveBy(const Offset(0, 180));
    await tester.pump(const Duration(milliseconds: 400));
    await reorderWithUnused.up();
    await tester.pumpAndSettle();
    expect(
      provider.project
          .getScenesForBeat('opening_image')
          .take(2)
          .map((scene) => scene.id),
      [scenes[0].id, scenes[1].id],
    );
    expect(tester.takeException(), isNull);
  });

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

  testWidgets('an assigned event must be moved to the pool before deletion', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1800, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    final project = StoryProject.createSampleProject();
    final event = project.getEventsForBeat('opening_image').first;
    final provider = StoryProvider(initialProject: project);
    addTearDown(provider.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => BeatDetailDialog.show(
                context,
                beat: BeatDefinition.getById('opening_image'),
                provider: provider,
              ),
              child: const Text('Open Beat'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open Beat'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Events (2)'));
    await tester.pumpAndSettle();
    final eventCard = find.ancestor(
      of: find.text(event.title),
      matching: find.byType(EventCard),
    );
    await tester.tap(
      find.descendant(
        of: eventCard,
        matching: find.byType(PopupMenuButton<String>),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Delete'), findsNothing);
    await tester.tap(find.text('Move to Pool'));
    await tester.pumpAndSettle();
    expect(event.beatId, isNull);
    expect(project.getUnassignedEvents(), contains(event));
  });

  testWidgets('Add Scene dialog supports title and location Enter navigation', (
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
    final locationField = find.descendant(
      of: find.byType(AlertDialog).last,
      matching: find.byKey(const ValueKey('slugline-location')),
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
              of: locationField,
              matching: find.byType(EditableText),
            ),
          )
          .focusNode
          .hasFocus,
      isTrue,
    );

    await tester.enterText(locationField, 'archive');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    final scene = project.scenes.singleWhere(
      (scene) => scene.title == 'A scene by keyboard',
    );
    expect(scene.beatId, 'opening_image');
    expect(scene.activeVersion.slugline, 'INT. ARCHIVE - DAY');
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

  testWidgets('scene summary and notes open multiline editors', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final project = StoryProject.createSampleProject();
    final scene = project.getScenesForBeat('opening_image').first;
    final version = scene.activeVersion;
    final originalNotes = version.notes;
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
    await tester.tap(find.text('Open Beat'));
    await tester.pumpAndSettle();

    final summaryPreview = find.byKey(const ValueKey('scene-summary-preview'));
    final notesPreview = find.byKey(const ValueKey('scene-notes-preview'));
    final summaryEditor = find.byKey(const ValueKey('scene-summary-editor'));
    final notesEditor = find.byKey(const ValueKey('scene-notes-editor'));
    const summary = 'A much longer summary.\nA second line of detail.';
    const notes = 'First revision thought.\nSecond revision thought.';

    await tester.tap(summaryPreview);
    await tester.pumpAndSettle();
    expect(
      (tester.widget<AlertDialog>(find.byType(AlertDialog)).title as Text).data,
      scene.title,
    );
    expect(
      tester
          .widget<TextField>(
            find.descendant(
              of: summaryEditor,
              matching: find.byType(TextField),
            ),
          )
          .maxLines,
      greaterThan(1),
    );
    await tester.enterText(summaryEditor, summary);
    expect(version.summary, isNot(summary));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(version.summary, summary);
    expect(version.notes, originalNotes);
    final summaryText = tester.widget<Text>(
      find.descendant(
        of: summaryPreview,
        matching: find.text('A much longer summary. A second line of detail.'),
      ),
    );
    expect(summaryText.maxLines, 1);
    expect(summaryText.overflow, TextOverflow.ellipsis);

    await tester.tap(notesPreview);
    await tester.pumpAndSettle();
    expect(
      (tester.widget<AlertDialog>(find.byType(AlertDialog)).title as Text).data,
      scene.title,
    );
    expect(
      tester
          .widget<TextField>(
            find.descendant(of: notesEditor, matching: find.byType(TextField)),
          )
          .maxLines,
      greaterThan(1),
    );
    await tester.enterText(notesEditor, notes);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(version.notes, originalNotes);

    await tester.tap(notesPreview);
    await tester.pumpAndSettle();
    await tester.enterText(notesEditor, notes);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(version.notes, notes);
    expect(version.summary, summary);
    final notesText = tester.widget<Text>(
      find.descendant(
        of: notesPreview,
        matching: find.text('First revision thought. Second revision thought.'),
      ),
    );
    expect(notesText.maxLines, 1);

    await tester.tap(summaryPreview);
    await tester.pumpAndSettle();
    expect(tester.widget<TextFormField>(summaryEditor).initialValue, summary);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(version.summary, summary);

    await tester.tap(find.text('v1: Draft 1 (Raw Action)'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: summaryPreview,
        matching: find.text(scene.versions.first.summary),
      ),
      findsOneWidget,
    );
    await tester.tap(summaryPreview);
    await tester.pumpAndSettle();
    await tester.enterText(summaryEditor, 'Summary for the first version');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(scene.versions.first.summary, 'Summary for the first version');
    expect(version.summary, summary);
    expect(version.notes, notes);
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

  testWidgets('each beat scrolls its own events without moving the board', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final project = StoryProject.createEmptyProject();
    for (final beatId in ['opening_image', 'theme_stated', 'b_story']) {
      for (var index = 0; index < 10; index++) {
        project.events.add(
          StoryEvent(
            id: '$beatId-$index',
            title: '$beatId event $index',
            beatId: beatId,
            orderIndex: index,
          ),
        );
      }
    }

    await tester.pumpWidget(BeatWorkApp(initialProject: project));
    await tester.pumpAndSettle();

    Finder beatCard(String label) =>
        find.ancestor(of: find.text(label), matching: find.byType(BeatCard));
    Finder eventList(Finder card) =>
        find.descendant(of: card, matching: find.byType(ListView));

    final firstCard = beatCard('BEAT 01');
    final secondCard = beatCard('BEAT 02');
    final firstList = eventList(firstCard);
    final secondList = eventList(secondCard);
    final firstController = tester.widget<ListView>(firstList).controller!;
    final secondController = tester.widget<ListView>(secondList).controller!;
    final board = find.ancestor(of: firstCard, matching: find.byType(ListView));
    final boardPosition = tester
        .state<ScrollableState>(
          find.descendant(of: board, matching: find.byType(Scrollable)).first,
        )
        .position;
    final boardOffset = boardPosition.pixels;

    expect(firstController.position.maxScrollExtent, greaterThan(0));
    expect(find.text('opening_image event 9').hitTestable(), findsNothing);

    await tester.sendEventToBinding(
      PointerScrollEvent(
        position: tester.getCenter(firstList),
        scrollDelta: const Offset(0, 1000),
      ),
    );
    await tester.pumpAndSettle();

    expect(firstController.offset, firstController.position.maxScrollExtent);
    expect(secondController.offset, 0);
    expect(boardPosition.pixels, boardOffset);
    expect(find.text('opening_image event 9').hitTestable(), findsOneWidget);
    expect(find.text('10 Events'), findsWidgets);

    final listRect = tester.getRect(firstList);
    await tester.dragFrom(
      Offset(listRect.right - 4, listRect.bottom - 10),
      const Offset(0, -80),
    );
    await tester.pumpAndSettle();
    expect(firstController.offset, 0);
    expect(secondController.offset, 0);
    expect(boardPosition.pixels, boardOffset);

    await tester.sendEventToBinding(
      PointerScrollEvent(
        position: tester.getCenter(firstList),
        scrollDelta: const Offset(0, 1000),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('opening_image event 9'));
    await tester.pumpAndSettle();
    expect(find.text('Edit Story Event'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    final lastEvent = find.text('opening_image event 9');
    final dragOffset =
        tester.getCenter(secondCard) - tester.getCenter(lastEvent);
    await tester.drag(lastEvent, dragOffset);
    await tester.pumpAndSettle();
    expect(
      project.events
          .firstWhere((event) => event.id == 'opening_image-9')
          .beatId,
      'theme_stated',
    );

    await tester.tap(find.widgetWithText(ChoiceChip, 'Act 2A'));
    await tester.pumpAndSettle();
    final filteredList = eventList(beatCard('BEAT 07'));
    expect(tester.widget<ListView>(filteredList).controller!.offset, 0);
    expect(find.text('b_story event 0').hitTestable(), findsOneWidget);
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
    expect(find.text('EXT. SPIDERTOWER ANTENNA - NIGHT'), findsOneWidget);
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
    expect(find.text('/*'), findsWidgets);
    expect(find.text('*/'), findsWidgets);
    final timelineSummary = tester.widget<Text>(
      find.textContaining(
        'Summary: Tightened pacing, introduced the ticking rain',
      ),
    );
    expect(timelineSummary.style?.color, StoryAct.act1.accentColor);
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
