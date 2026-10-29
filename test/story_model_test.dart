import 'package:flutter_test/flutter_test.dart';
import 'package:beatwork/models/beat_model.dart';
import 'package:beatwork/models/scene_model.dart';
import 'package:beatwork/models/story_event.dart';
import 'package:beatwork/models/story_project.dart';
import 'package:beatwork/services/export_service.dart';
import 'package:beatwork/services/project_codec.dart';

void main() {
  group('Story Event Tests', () {
    test('Ignores legacy emotional charge when loading saved events', () {
      final event = StoryEvent.fromJson({
        'id': 'event-1',
        'title': 'A story event',
        'emotionalCharge': 'negative',
      });

      expect(event.title, 'A story event');
      expect(event.toJson().containsKey('emotionalCharge'), isFalse);
    });
  });

  group('Save the Cat Beat Model Tests', () {
    test(
      'Has 19 ordered Save the Cat beats including the five finale stages',
      () {
        expect(BeatDefinition.saveTheCatBeats.length, 19);
        expect(BeatDefinition.saveTheCatBeats.first.name, 'Opening Image');
        expect(BeatDefinition.saveTheCatBeats.last.name, 'Final Image');
        expect(BeatDefinition.getById('finale').name, 'Gather the Team');
        expect(
          BeatDefinition.saveTheCatBeats.map((beat) => beat.number),
          List.generate(19, (index) => index + 1),
        );
        expect(
          BeatDefinition.saveTheCatBeats
              .skip(13)
              .take(5)
              .map((beat) => beat.name),
          [
            'Gather the Team',
            'Execute the Plan',
            'High Tower Surprise',
            'Dig Down Deep',
            'Execution of the New Plan',
          ],
        );
      },
    );

    test('Beats are grouped across the 4 acts', () {
      final act1Beats = BeatDefinition.saveTheCatBeats
          .where((b) => b.act == StoryAct.act1)
          .toList();
      final act2ABeats = BeatDefinition.saveTheCatBeats
          .where((b) => b.act == StoryAct.act2A)
          .toList();
      final act2BBeats = BeatDefinition.saveTheCatBeats
          .where((b) => b.act == StoryAct.act2B)
          .toList();
      final act3Beats = BeatDefinition.saveTheCatBeats
          .where((b) => b.act == StoryAct.act3)
          .toList();

      expect(act1Beats.length, 6); // 1 to 6
      expect(act2ABeats.length, 3); // 7 to 9
      expect(act2BBeats.length, 4); // 10 to 13
      expect(act3Beats.length, 6); // 14 to 19
      expect(act1Beats.last.id, 'break_into_two');
      expect(act2ABeats.last.id, 'midpoint');
      expect(act2BBeats.last.id, 'break_into_three');
    });
  });

  group('Story Project & Scene Versioning Tests', () {
    test('Project Protobuf round-trip preserves nested project content', () {
      final project = StoryProject.createSampleProject();
      project.authorEmail = 'writer@example.com';

      final decoded = ProjectCodec.decode(ProjectCodec.encode(project));

      expect(decoded.toJson(), project.toJson());
      expect(decoded.authorEmail, 'writer@example.com');
    });

    test('Sample project contains pre-populated events and scenes', () {
      final project = StoryProject.createSampleProject();
      expect(project.events.isNotEmpty, true);
      expect(project.scenes.isNotEmpty, true);

      // Check unassigned pool
      final pool = project.getUnassignedEvents();
      expect(pool.isNotEmpty, true);

      // Check beat assignment
      final openImageEvents = project.getEventsForBeat('opening_image');
      expect(openImageEvents.length, 2);
    });

    test('Scene creates next version and switches active version', () {
      final scene = Scene(
        id: 'test-scene-1',
        beatId: 'opening_image',
        title: 'Meeting in the Diner',
      );

      expect(scene.versions.length, 1);
      expect(scene.activeVersion.versionNumber, 1);

      // Create new version
      final v2 = scene.createNewVersion(
        label: 'Tightened Dialogue',
        slugline: 'INT. DINER - NIGHT',
        scriptContent: 'KAEL\nCheck the core.',
      );

      expect(scene.versions.length, 2);
      expect(scene.activeVersionId, v2.id);
      expect(scene.activeVersion.label, 'Tightened Dialogue');
      expect(scene.activeVersion.versionNumber, 2);

      // Old version remains accessible for reference
      final v1 = scene.versions.firstWhere((v) => v.versionNumber == 1);
      expect(v1.versionNumber, 1);
    });

    test(
      'Collected timeline collects scenes in beat order and timeline order',
      () {
        final project = StoryProject(id: 'proj-1', title: 'Timeline Test');

        // Scene in Beat 4 (Catalyst)
        final sCat = Scene(
          id: 'sc-cat',
          beatId: 'catalyst',
          title: 'The Explosion',
          timelineOrder: 0,
        );

        // Scenes in Beat 1 (Opening Image)
        final sOpen2 = Scene(
          id: 'sc-open-2',
          beatId: 'opening_image',
          title: 'Waking Up',
          timelineOrder: 1,
        );
        final sOpen1 = Scene(
          id: 'sc-open-1',
          beatId: 'opening_image',
          title: 'Alarm Ringing',
          timelineOrder: 0,
        );

        project.scenes.addAll([sCat, sOpen2, sOpen1]);

        final collected = project.getCollectedTimeline();
        expect(collected.length, 3);

        // Should order Beat 1 scenes first (sOpen1 then sOpen2), then Beat 4 scene (sCat)
        expect(collected[0].scene.id, 'sc-open-1');
        expect(collected[1].scene.id, 'sc-open-2');
        expect(collected[2].scene.id, 'sc-cat');
      },
    );
  });

  group('Export Service Tests', () {
    test('Generates valid Final Draft (.fdx) XML content', () {
      final project = StoryProject.createSampleProject();
      project.authorEmail = 'writer@example.com';
      final firstEntry = project.getCollectedTimeline().first;
      firstEntry.scene.activeVersion.summary = 'Internal scene summary';
      firstEntry.scene.activeVersion.notes = 'Internal writer note';
      final mappedEvent = project.events.first;
      firstEntry.scene.mappedEventIds.add(mappedEvent.id);
      final fdx = ExportService.generateFinalDraftFdx(project);

      expect(fdx.contains('<?xml version="1.0"'), true);
      expect(fdx.contains('<FinalDraft DocumentType="Script"'), true);
      expect(fdx.contains('<TitlePage>'), true);
      expect(fdx.contains('<Paragraph Type="Author">'), true);
      expect(fdx.contains('<Paragraph Type="Contact">'), true);
      expect(fdx.contains('Antigravity Screenwriter'), true);
      expect(fdx.contains('writer@example.com'), true);
      expect(fdx.contains('<Paragraph Type="Scene Heading">'), true);
      expect(fdx.contains('</FinalDraft>'), true);
      expect(fdx.contains('The Chronos Cipher'), true);
      expect('EXT. SPIDERTOWER ANTENNA - NIGHT'.allMatches(fdx).length, 1);
      expect(fdx.contains('SAVE THE CAT:'), false);
      expect(fdx.contains('BEAT 1:'), false);
      expect(fdx.contains('Mapped Beat Events'), false);
      expect(fdx.contains(mappedEvent.title), false);
      expect(fdx.contains('Internal scene summary'), false);
      expect(fdx.contains('Internal writer note'), false);
    });

    test('Generates valid Fountain plain text content', () {
      final project = StoryProject.createSampleProject();
      project.authorEmail = 'writer@example.com';
      final firstScene = project.getCollectedTimeline().first.scene;
      final firstEntry = project.getCollectedTimeline().first;
      firstScene.activeVersion.summary = 'Internal scene summary';
      firstScene.activeVersion.notes = 'Internal writer note';
      final mappedEvent = project.events.first;
      firstScene.mappedEventIds.add(mappedEvent.id);
      final fountain = ExportService.generateFountain(project);

      expect(fountain.contains('Title: The Chronos Cipher'), true);
      expect(fountain.contains('Author: Antigravity Screenwriter'), true);
      expect(fountain.contains('Contact: writer@example.com'), true);
      expect(fountain.contains('SAVE THE CAT:'), false);
      expect(fountain.contains('BEAT ${firstEntry.beat.number}'), false);
      expect(fountain.contains('EXT. SPIDERTOWER ANTENNA - NIGHT'), true);
      expect(fountain.contains('Events:'), false);
      expect(fountain.contains(mappedEvent.title), false);
      expect(fountain.contains('Internal scene summary'), false);
      expect(fountain.contains('Internal writer note'), false);
      expect(fountain.contains('[['), false);
    });

    test('Generates Screenplay PDF bytes', () async {
      final project = StoryProject.createSampleProject();
      final pdfBytes = await ExportService.generateScreenplayPdf(project);

      expect(pdfBytes.isNotEmpty, true);
      // PDF header magic numbers '%PDF'
      expect(pdfBytes[0], 0x25); // %
      expect(pdfBytes[1], 0x50); // P
      expect(pdfBytes[2], 0x44); // D
      expect(pdfBytes[3], 0x46); // F
    });

    test(
      'Generates BeatWork Timeline PDF directly from project data',
      () async {
        final project = StoryProject.createSampleProject();
        final scene = project.getCollectedTimeline().first.scene;
        scene.activeVersion.summary = 'Summary for the PDF';
        scene.activeVersion.notes = 'Writer note for the PDF';
        scene.mappedEventIds.add(project.events.first.id);
        final pdfBytes = await ExportService.generateBeatWorkTimelinePdf(
          project,
        );

        expect(pdfBytes.take(4).toList(), [0x25, 0x50, 0x44, 0x46]);
        expect(pdfBytes.length, greaterThan(1000));
      },
    );
  });
}
