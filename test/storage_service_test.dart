import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beatwork/models/story_project.dart';
import 'package:beatwork/models/author_profile.dart';
import 'package:beatwork/proto/story_project.pb.dart';
import 'package:beatwork/services/export_service.dart';
import 'package:beatwork/services/storage_service.dart';
import 'package:beatwork/state/story_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const accessChannel = MethodChannel('beatwork/document_access');
  late Directory temporaryDirectory;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'beatwork_test_',
    );
    StorageService.overrideDirectory = temporaryDirectory;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          accessChannel,
          (call) async => call.method == 'restore' ? false : null,
        );
  });

  tearDown(() async {
    StorageService.overrideDirectory = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(accessChannel, null);
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

  test(
    'selected projects create bookmarks and recent projects restore them',
    () async {
      final path = '${temporaryDirectory.path}/selected.beats';
      await StorageService.saveDocumentToPath(
        StoryProject.createSampleProject(),
        path,
      );
      final calls = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(accessChannel, (call) async {
            calls.add('${call.method}:${call.arguments}');
            return call.method == 'restore' ? true : null;
          });

      await StorageService.openDocument(path, userSelected: true);
      expect(calls, ['remember:$path']);
      calls.clear();
      await StorageService.openDocument(path);
      expect(calls, ['restore:$path', 'remember:$path']);
    },
    skip: !Platform.isMacOS,
  );

  test(
    'bookmark failures are surfaced and inaccessible recent files stay listed',
    () async {
      final path = '${temporaryDirectory.path}/recent.beats';
      await StorageService.saveDocumentToPath(
        StoryProject.createSampleProject(),
        path,
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(accessChannel, (call) async {
            if (call.method == 'restore') {
              throw PlatformException(code: 'document_access_error');
            }
            return null;
          });

      await expectLater(
        StorageService.openDocument(path),
        throwsA(isA<PlatformException>()),
      );
      await File(path).delete();
      expect(
        (await StorageService.listRecentDocuments()).map((entry) => entry.path),
        contains(path),
      );
    },
    skip: !Platform.isMacOS,
  );

  test(
    'Save As remembers the selected project for future access',
    () async {
      final path = '${temporaryDirectory.path}/saved.beats';
      final originalPicker = FilePickerPlatform.instance;
      FilePickerPlatform.instance = _SavePicker(path);
      addTearDown(() => FilePickerPlatform.instance = originalPicker);
      final calls = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(accessChannel, (call) async {
            calls.add('${call.method}:${call.arguments}');
            return call.method == 'restore' ? true : null;
          });

      expect(
        await StorageService.saveDocumentAs(StoryProject.createSampleProject()),
        path,
      );
      expect(calls, ['remember:$path']);
      calls.clear();
      await StorageService.openDocument(path);
      expect(calls, ['restore:$path', 'remember:$path']);
    },
    skip: !Platform.isMacOS,
  );

  test(
    'shared author survives restarts and project changes without being stored in documents',
    () async {
      final provider = StoryProvider(
        initialProject: StoryProject.createEmptyProject(),
      );
      addTearDown(provider.dispose);
      await provider.updateAuthor(
        const AuthorProfile(name: 'Writer', email: 'writer@example.com'),
      );
      final path = '${temporaryDirectory.path}/project.beats';
      await StorageService.saveDocumentToPath(provider.project, path);
      final document =
          StoryProjectDocument.fromBuffer(
                await File(path).readAsBytes(),
              ).toProto3Json()
              as Map<String, dynamic>;
      expect(document, isNot(contains('author')));
      expect(document, isNot(contains('authorEmail')));
      provider.newDocument(
        StoryProject.createEmptyProject(title: 'New project'),
      );
      expect(provider.author.name, 'Writer');
      expect(await provider.openDocument(path), isTrue);
      expect(provider.author.email, 'writer@example.com');
      expect(
        ExportService.generateFountain(
          provider.project,
          author: provider.author,
        ),
        contains('Author: Writer\nContact: writer@example.com'),
      );
      final reopened = StoryProvider(
        initialAuthor: await StorageService.loadAuthorProfile(),
      );
      addTearDown(reopened.dispose);
      expect(reopened.author.name, 'Writer');
      expect(reopened.author.email, 'writer@example.com');
    },
  );

  test('invalid author settings and save failures are surfaced', () async {
    final settings = File('${temporaryDirectory.path}/author_profile.json');
    await settings.writeAsString('not JSON');
    expect(() => StorageService.loadAuthorProfile(), throwsFormatException);

    StorageService.overrideDirectory = Directory(settings.path);
    final provider = StoryProvider();
    addTearDown(provider.dispose);
    await expectLater(
      provider.updateAuthor(const AuthorProfile(name: 'New writer')),
      throwsA(isA<FileSystemException>()),
    );
    expect(provider.author.name, AuthorProfile.defaultName);
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

  test('scene edits mark the document dirty and persist', () async {
    final project = StoryProject.createSampleProject();
    final scene = project.scenes.first;
    final path = '${temporaryDirectory.path}/scene.beats';
    await StorageService.saveDocumentToPath(project, path);
    final provider = StoryProvider(initialProject: project, documentPath: path);
    addTearDown(provider.dispose);

    final edits = <void Function()>[
      () {
        scene.title = 'New scene title';
        provider.updateScene(scene);
      },
      () => provider.updateActiveVersionContent(
        scene.id,
        slugline: 'EXT. ROOF - DAY',
      ),
      () => provider.updateActiveVersionContent(
        scene.id,
        scriptContent: 'New script',
      ),
      () =>
          provider.updateActiveVersionContent(scene.id, summary: 'New summary'),
      () => provider.updateActiveVersionContent(scene.id, notes: 'New notes'),
      () => provider.setSceneUnused(scene.id, true),
      () => provider.createNextSceneVersion(scene.id, label: 'New version'),
    ];

    for (final edit in edits) {
      edit();
      expect(provider.hasUnsavedChanges, isTrue);
      expect(await provider.saveDocument(), isTrue);
      expect(provider.hasUnsavedChanges, isFalse);
      final saved = await StorageService.openDocument(path);
      expect(saved.scenes.first.toJson(), scene.toJson());
    }
  });

  test(
    'macOS saves a selected document without requiring a sibling temporary file',
    () async {
      final path = '${temporaryDirectory.path}/selected.beats';
      final project = StoryProject.createSampleProject();
      await StorageService.saveDocumentToPath(project, path);
      await Directory('$path.tmp').create();
      final provider = StoryProvider(
        initialProject: project,
        documentPath: path,
      );
      addTearDown(provider.dispose);
      final saved = Completer<void>();
      provider.addListener(() {
        if (!provider.hasUnsavedChanges && !saved.isCompleted) {
          saved.complete();
        }
      });

      final scene = project.scenes.first;
      provider.updateActiveVersionContent(scene.id, scriptContent: 'Autosaved');
      expect(provider.hasUnsavedChanges, isTrue);
      await saved.future.timeout(const Duration(seconds: 5));

      final reopened = await StorageService.openDocument(path);
      expect(reopened.scenes.first.activeVersion.scriptContent, 'Autosaved');
    },
    skip: !Platform.isMacOS,
  );

  test('failed scene saves leave the document dirty', () async {
    final project = StoryProject.createSampleProject();
    final scene = project.scenes.first;
    final path = '${temporaryDirectory.path}/blocked.beats';
    await Directory(path).create();
    final provider = StoryProvider(initialProject: project, documentPath: path);
    addTearDown(provider.dispose);

    provider.updateActiveVersionContent(scene.id, scriptContent: 'Unsaved');

    expect(await provider.saveDocument(), isFalse);
    expect(provider.hasUnsavedChanges, isTrue);
    expect(scene.activeVersion.scriptContent, 'Unsaved');
  });
}

class _SavePicker extends FilePickerPlatform {
  final String path;

  _SavePicker(this.path);

  @override
  Future<Uri?> saveFile({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
    String? dialogTitle,
    String? initialDirectory,
    Function(FilePickerStatus)? onFileSaving,
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    await File(path).writeAsBytes(bytes);
    return Uri.file(path);
  }
}
