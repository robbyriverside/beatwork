import 'package:flutter_test/flutter_test.dart';
import 'package:beatwork/models/beat_model.dart';
import 'package:beatwork/models/scene_model.dart';
import 'package:beatwork/models/story_event.dart';
import 'package:beatwork/models/story_project.dart';
import 'package:beatwork/services/export_service.dart';

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
    test('Has exactly 15 canonical Save the Cat beats', () {
      expect(BeatDefinition.saveTheCatBeats.length, 15);
      expect(BeatDefinition.saveTheCatBeats.first.name, 'Opening Image');
      expect(BeatDefinition.saveTheCatBeats.last.name, 'Final Image');
    });

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

      expect(act1Beats.length, 5); // 1 to 5
      expect(act2ABeats.length, 4); // 6 to 9
      expect(act2BBeats.length, 3); // 10 to 12
      expect(act3Beats.length, 3); // 13 to 15
    });
  });

  group('Story Project & Scene Versioning Tests', () {
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

    test('Collected timeline collects scenes in beat order and timeline order', () {
      final project = StoryProject(
        id: 'proj-1',
        title: 'Timeline Test',
      );

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
    });
  });

  group('Export Service Tests', () {
    test('Generates valid Final Draft (.fdx) XML content', () {
      final project = StoryProject.createSampleProject();
      final fdx = ExportService.generateFinalDraftFdx(project);

      expect(fdx.contains('<?xml version="1.0"'), true);
      expect(fdx.contains('<FinalDraft DocumentType="Script"'), true);
      expect(fdx.contains('<Paragraph Type="Scene Heading">'), true);
      expect(fdx.contains('</FinalDraft>'), true);
      expect(fdx.contains('The Chronos Cipher'), true);
    });

    test('Generates valid Fountain plain text content', () {
      final project = StoryProject.createSampleProject();
      final fountain = ExportService.generateFountain(project);

      expect(fountain.contains('Title: The Chronos Cipher'), true);
      expect(fountain.contains('SAVE THE CAT:'), true);
      expect(fountain.contains('EXT. SPIDERTOWER ANTENNA - NIGHT'), true);
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
  });
}
