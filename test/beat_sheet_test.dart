import 'package:beatwork/models/beat_model.dart';
import 'package:beatwork/models/author_profile.dart';
import 'package:beatwork/models/beat_sheet.dart';
import 'package:beatwork/models/scene_model.dart';
import 'package:beatwork/models/story_project.dart';
import 'package:beatwork/proto/story_project.pb.dart';
import 'package:beatwork/services/export_service.dart';
import 'package:beatwork/services/project_codec.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Save the Cat YAML preserves the existing beats and guidance', () async {
    final yaml = await rootBundle.loadString(
      'assets/beat_sheets/save_the_cat.yaml',
    );
    final sheet = BeatSheet.fromYaml(yaml, 110);
    expect(sheet.beats.length, BeatDefinition.saveTheCatBeats.length);
    for (var i = 0; i < sheet.beats.length; i++) {
      final actual = sheet.beats[i];
      final expected = BeatDefinition.saveTheCatBeats[i];
      expect(actual.id, expected.id);
      expect(actual.name, expected.name);
      expect(actual.targetPage, expected.targetPage);
      expect(actual.percentage, expected.percentage);
      expect(actual.shortSummary, expected.shortSummary);
      expect(actual.guidance, expected.guidance);
      expect(actual.act.title, expected.act.title);
      expect(actual.icon, expected.icon);
    }
  });

  test(
    'five-act estimates scale with length and never have fewer than three beats per act',
    () async {
      final yaml = await rootBundle.loadString(
        'assets/beat_sheets/five_act.yaml',
      );
      for (final (pages, expected) in [
        (1, 15),
        (75, 15),
        (110, 22),
        (200, 40),
      ]) {
        final sheet = BeatSheet.fromYaml(yaml, pages);
        expect(sheet.acts.length, 5);
        expect(sheet.beats.length, expected);
        for (final act in sheet.acts) {
          expect(
            sheet.beats.where((beat) => beat.act == act).length,
            greaterThanOrEqualTo(3),
          );
        }
        expect(sheet.beats.map((beat) => beat.id).toSet().length, expected);
        expect(
          sheet.beats.every(
            (beat) => beat.guidance.isNotEmpty && beat.shortSummary.isNotEmpty,
          ),
          isTrue,
        );
      }
      expect(() => BeatSheet.fromYaml(yaml, 0), throwsFormatException);
    },
  );

  test(
    'hierarchy links five complete acts and scales with target length',
    () async {
      final yaml = await rootBundle.loadString(
        'assets/beat_sheets/five_act_hierarchy.yaml',
      );
      for (final (pages, expected) in [(75, 15), (110, 22), (200, 40)]) {
        final sheet = BeatSheet.fromYaml(yaml, pages);
        expect(sheet.name, 'Five-Act Hierarchy');
        expect(sheet.acts.length, 5);
        expect(sheet.beats.length, expected);
        for (var index = 0; index < sheet.acts.length; index++) {
          final beats = sheet.beats
              .where((beat) => beat.act == sheet.acts[index])
              .toList();
          final prefix = 'act${index + 1}';
          expect(beats.length, greaterThanOrEqualTo(3));
          expect(beats.first.id, '${prefix}_conflict');
          expect(beats[1].id, '${prefix}_climax');
          expect(beats.last.id, '${prefix}_resolution');
          expect(
            beats.every(
              (beat) =>
                  beat.guidance.isNotEmpty && beat.shortSummary.isNotEmpty,
            ),
            isTrue,
          );
        }
        final project = StoryProject.createEmptyProject(
          beatSheetYaml: yaml,
          targetPageCount: pages,
        );
        final reloaded = ProjectCodec.decode(ProjectCodec.encode(project));
        expect(
          reloaded.beatSheet.beats.map((beat) => beat.id),
          sheet.beats.map((beat) => beat.id),
        );
        expect(reloaded.beatSheet.name, sheet.name);
      }
    },
  );

  test(
    'project snapshot, duplicate, protobuf, and export retain the selected sheet',
    () async {
      final yaml = await rootBundle.loadString(
        'assets/beat_sheets/five_act.yaml',
      );
      final project = StoryProject.createEmptyProject(
        beatSheetYaml: yaml,
        targetPageCount: 110,
      );
      expect(project.beatSheet.beats.length, 22);
      expect(project.beatSheetYaml, contains('"mode":"fixed"'));
      final first = project.beatSheet.beats.first;
      final last = project.beatSheet.beats.last;
      project.scenes.addAll([
        Scene(id: 'last', beatId: last.id, title: 'Last scene'),
        Scene(id: 'first', beatId: first.id, title: 'First scene'),
      ]);
      project.scenes[0].activeVersion.scriptContent = 'Last scene';
      project.scenes[1].activeVersion.scriptContent = 'First scene';

      for (final copy in [
        project.duplicate(),
        StoryProject.fromJson(project.toJson()),
        ProjectCodec.decode(ProjectCodec.encode(project)),
      ]) {
        expect(copy.targetPageCount, 110);
        expect(copy.beatSheetYaml, project.beatSheetYaml);
        expect(
          copy.beatSheet.beats.map((beat) => beat.id),
          project.beatSheet.beats.map((beat) => beat.id),
        );
        expect(copy.getCollectedTimeline().map((entry) => entry.scene.id), [
          'first',
          'last',
        ]);
        final fountain = ExportService.generateFountain(
          copy,
          author: const AuthorProfile(),
        );
        expect(fountain, contains('First scene'));
        expect(fountain, contains('Last scene'));
        expect(
          fountain.indexOf('First scene'),
          lessThan(fountain.indexOf('Last scene')),
        );
      }
    },
  );

  test(
    'documents predating beat sheets use the legacy Save the Cat layout',
    () {
      final document = StoryProjectDocument(id: 'old', title: 'Old project');
      final project = ProjectCodec.decode(document.writeToBuffer());
      expect(project.beatSheet.id, 'save_the_cat');
      expect(project.beatSheet.beats.length, 19);
      expect(project.targetPageCount, 110);
    },
  );

  test('a saved sheet without a valid target length is rejected', () async {
    final yaml = await rootBundle.loadString(
      'assets/beat_sheets/five_act.yaml',
    );
    final document = StoryProjectDocument(
      id: 'invalid',
      title: 'Invalid project',
      beatSheetYaml: yaml,
    );
    expect(
      () => ProjectCodec.decode(document.writeToBuffer()),
      throwsFormatException,
    );
  });
}
