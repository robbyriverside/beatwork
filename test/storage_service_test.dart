import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:beatwork/models/story_project.dart';
import 'package:beatwork/services/storage_service.dart';
import 'package:beatwork/state/story_provider.dart';

void main() {
  late Directory temporaryDirectory;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'beatwork_test_',
    );
    StorageService.overrideDirectory = temporaryDirectory;
  });

  tearDown(() async {
    StorageService.overrideDirectory = null;
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  test(
    'saves and opens a binary .beats document and records it as recent',
    () async {
      final project = StoryProject.createSampleProject();
      final path = '${temporaryDirectory.path}/sample.beats';

      await StorageService.saveDocumentToPath(project, path);

      final bytes = await File(path).readAsBytes();
      expect(bytes.first, isNot(0x7b));
      final loaded = await StorageService.openDocument(path);
      expect(loaded.toJson(), project.toJson());

      final recent = await StorageService.listRecentDocuments();
      expect(recent, hasLength(1));
      expect(recent.single.path, path);
      expect(recent.single.title, project.title);
    },
  );

  test('rejects files without the .beats extension', () async {
    final path = '${temporaryDirectory.path}/project.json';
    await File(path).writeAsString('{}');

    expect(
      () => StorageService.openDocument(path),
      throwsA(isA<FormatException>()),
    );
  });

  test('events must be in the pool and scenes unused before deletion', () {
    final project = StoryProject.createEmptyProject();
    final provider = StoryProvider(initialProject: project);
    addTearDown(provider.dispose);
    final event = provider.createEvent(title: 'Event', beatId: 'opening_image');
    final scene = provider.createScene(beatId: 'opening_image', title: 'Scene');
    expect(() => provider.deleteEvent(event.id), throwsStateError);
    expect(() => provider.deleteScene(scene.id), throwsStateError);
    expect(project.events, contains(event));
    expect(project.scenes, contains(scene));

    provider.unassignEvent(event.id);
    provider.deleteEvent(event.id);
    provider.setSceneUnused(scene.id, true);
    provider.deleteScene(scene.id);
    expect(project.events, isEmpty);
    expect(project.scenes, isEmpty);
  });

  test('unused scenes keep their state after saving and reopening', () async {
    final project = StoryProject.createEmptyProject();
    final provider = StoryProvider(initialProject: project);
    addTearDown(provider.dispose);
    final scene = provider.createScene(beatId: 'opening_image', title: 'Scene');
    provider.setSceneUnused(scene.id, true);
    final path = '${temporaryDirectory.path}/unused.beats';
    await StorageService.saveDocumentToPath(project, path);
    final loaded = await StorageService.openDocument(path);
    expect(loaded.scenes.single.isUnused, isTrue);
    expect(loaded.getCollectedTimeline(), isEmpty);
  });

  test(
    'untitled edits remain in memory instead of using legacy JSON storage',
    () async {
      final provider = StoryProvider(
        initialProject: StoryProject.createEmptyProject(),
      );
      addTearDown(provider.dispose);

      provider.updateProjectMeta(title: 'Untitled changes');

      expect(provider.hasUnsavedChanges, isTrue);
      expect(provider.documentPath, isNull);
      expect(
        await Directory(
          '${temporaryDirectory.path}/beatwork_projects',
        ).exists(),
        isFalse,
      );
    },
  );

  test('edits to a named document autosave to its existing path', () async {
    final project = StoryProject.createEmptyProject(title: 'Before edit');
    final path = '${temporaryDirectory.path}/named.beats';
    await StorageService.saveDocumentToPath(project, path);
    final provider = StoryProvider(initialProject: project, documentPath: path);
    addTearDown(provider.dispose);

    provider.updateProjectMeta(title: 'After edit');
    expect(await provider.saveDocument(), isTrue);

    final loaded = await StorageService.openDocument(path);
    expect(loaded.title, 'After edit');
    expect(provider.hasUnsavedChanges, isFalse);
  });
}
