import 'package:beatwork/models/scene_model.dart';
import 'package:beatwork/models/beat_model.dart';
import 'package:beatwork/models/slugline.dart';
import 'package:beatwork/models/story_event.dart';
import 'package:beatwork/models/story_project.dart';
import 'package:beatwork/widgets/slugline_fields.dart';
import 'package:beatwork/widgets/scene_editor_view.dart';
import 'package:beatwork/state/story_provider.dart';
import 'package:beatwork/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('slugline fields have aligned borders', (tester) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 600,
              child: SluglineFields(
                project: StoryProject.createEmptyProject(),
                slugline: 'INT. OFFICE - DAY',
                locationFocusNode: focus,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      ),
    );

    Rect fieldBounds(String key) => tester.getRect(
      find.descendant(
        of: find.byKey(ValueKey(key)),
        matching: find.byType(InputDecorator),
      ),
    );

    final prefix = fieldBounds('slugline-prefix');
    final location = fieldBounds('slugline-location');
    final time = fieldBounds('slugline-time');
    expect(location.top, prefix.top);
    expect(location.bottom, prefix.bottom);
    expect(time.top, prefix.top);
    expect(time.bottom, prefix.bottom);

    await tester.tap(find.byKey(const ValueKey('slugline-location')));
    await tester.pumpAndSettle();
    expect(
      fieldBounds('slugline-location').bottom,
      fieldBounds('slugline-prefix').bottom,
    );
    expect(
      fieldBounds('slugline-time').bottom,
      fieldBounds('slugline-prefix').bottom,
    );
  });

  test(
    'parses and formats headings without splitting hyphenated locations',
    () {
      final slugline = Slugline.parse('ext. NEO-CHICAGO - NIGHT')!;
      expect(slugline.prefix, 'EXT.');
      expect(slugline.location, 'NEO-CHICAGO');
      expect(slugline.time, 'NIGHT');
      expect(slugline.format(), 'EXT. NEO-CHICAGO - NIGHT');
      expect(Slugline.parse('INT. - DAY')!.location, '');
      expect(
        Slugline.parse('INT. OFFICE - BACK ROOM - DAY')!.location,
        'OFFICE - BACK ROOM',
      );
      expect(Slugline.parse('a nonstandard heading'), isNull);
    },
  );

  testWidgets('chooses project locations, prefix and time', (tester) async {
    final project = StoryProject.createEmptyProject();
    project.events.add(
      StoryEvent(id: 'e', title: 'Event', location: 'Library'),
    );
    project.scenes.add(
      Scene(
        id: 's',
        beatId: 'opening_image',
        title: 'Scene',
        versions: [
          SceneVersion(
            id: 'v1',
            versionNumber: 1,
            slugline: 'EXT. ROOF - NIGHT',
          ),
          SceneVersion(
            id: 'v2',
            versionNumber: 2,
            slugline: 'INT. library - DAY',
          ),
        ],
      ),
    );
    final focus = FocusNode();
    addTearDown(focus.dispose);
    String? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 600,
            child: SluglineFields(
              project: project,
              slugline: 'INT. - DAY',
              locationFocusNode: focus,
              onChanged: (value) => result = value,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('slugline-location-menu')));
    await tester.pumpAndSettle();
    expect(find.text('LIBRARY'), findsOneWidget);
    expect(find.text('ROOF'), findsOneWidget);
    await tester.tap(find.text('ROOF'));
    await tester.pumpAndSettle();
    expect(result, 'INT. ROOF - DAY');

    await tester.tap(find.byKey(const ValueKey('slugline-prefix')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('EXT.').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('slugline-time')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('NIGHT').last);
    await tester.pumpAndSettle();
    expect(result, 'EXT. ROOF - NIGHT');

    await tester.enterText(
      find.byKey(const ValueKey('slugline-location')),
      'new location',
    );
    expect(result, 'EXT. NEW LOCATION - NIGHT');
  });

  testWidgets('slugline fields remain usable in a narrow editor', (
    tester,
  ) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);
    String? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 320,
              child: SluglineFields(
                project: StoryProject.createEmptyProject(),
                slugline: 'INT. OFFICE - DAY',
                locationFocusNode: focus,
                onChanged: (value) => result = value,
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    final prefix = tester.getRect(
      find.descendant(
        of: find.byKey(const ValueKey('slugline-prefix')),
        matching: find.byType(InputDecorator),
      ),
    );
    final location = tester.getRect(
      find.descendant(
        of: find.byKey(const ValueKey('slugline-location')),
        matching: find.byType(InputDecorator),
      ),
    );
    expect(location.top, prefix.top);
    expect(location.bottom, prefix.bottom);
    await tester.enterText(
      find.byKey(const ValueKey('slugline-location')),
      'hall',
    );
    expect(result, 'INT. HALL - DAY');
  });

  testWidgets('editor preserves old headings and switches scene versions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final project = StoryProject.createEmptyProject();
    final scene = Scene(
      id: 's',
      beatId: 'opening_image',
      title: 'Scene',
      activeVersionId: 'v1',
      versions: [
        SceneVersion(id: 'v1', versionNumber: 1, slugline: 'Legacy heading'),
        SceneVersion(id: 'v2', versionNumber: 2, slugline: 'EXT. ROOF - RAIN'),
      ],
    );
    project.scenes.add(scene);
    final provider = StoryProvider(initialProject: project);
    final bodyFocus = FocusNode();
    addTearDown(provider.dispose);
    addTearDown(bodyFocus.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListenableBuilder(
            listenable: provider,
            builder: (context, _) => SceneEditorView(
              scene: scene,
              beat: BeatDefinition.getById('opening_image'),
              provider: provider,
              bodyFocusNode: bodyFocus,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Existing unstructured heading'),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const ValueKey('scene-script-body')),
      'Script text',
    );
    expect(scene.activeVersion.slugline, 'Legacy heading');

    await tester.tap(find.byKey(const ValueKey('scene-title-field')));
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    expect(
      tester
          .widget<EditableText>(
            find.descendant(
              of: find.byKey(const ValueKey('slugline-location')),
              matching: find.byType(EditableText),
            ),
          )
          .focusNode
          .hasFocus,
      isTrue,
    );

    provider.setActiveSceneVersion(scene.id, 'v2');
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('slugline-location')))
          .controller!
          .text,
      'ROOF',
    );
    expect(find.text('RAIN'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('slugline-location')),
      'garden',
    );
    expect(scene.activeVersion.slugline, 'EXT. GARDEN - RAIN');
    expect(scene.versions.first.slugline, 'Legacy heading');
  });
}
