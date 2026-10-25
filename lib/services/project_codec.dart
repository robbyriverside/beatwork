import 'package:fixnum/fixnum.dart';

import '../models/scene_model.dart';
import '../models/story_event.dart';
import '../models/story_project.dart';
import '../proto/story_project.pb.dart';

class ProjectCodec {
  static List<int> encode(StoryProject project) =>
      _toDocument(project).writeToBuffer();

  static StoryProject decode(List<int> bytes) =>
      _fromDocument(StoryProjectDocument.fromBuffer(bytes));

  static StoryProjectDocument _toDocument(StoryProject project) {
    return StoryProjectDocument(
      id: project.id,
      title: project.title,
      logline: project.logline,
      genre: project.genre,
      author: project.author,
      isSample: project.isSample,
      events: project.events.map(
        (event) => StoryEventDocument(
          id: event.id,
          title: event.title,
          description: event.description,
          beatId: event.beatId,
          characters: event.characters,
          location: event.location,
          orderIndex: event.orderIndex,
          createdAtMicros: Int64(event.createdAt.microsecondsSinceEpoch),
        ),
      ),
      scenes: project.scenes.map(
        (scene) => SceneDocument(
          id: scene.id,
          beatId: scene.beatId,
          title: scene.title,
          timelineOrder: scene.timelineOrder,
          mappedEventIds: scene.mappedEventIds,
          versions: scene.versions.map(
            (version) => SceneVersionDocument(
              id: version.id,
              versionNumber: version.versionNumber,
              label: version.label,
              slugline: version.slugline,
              summary: version.summary,
              scriptContent: version.scriptContent,
              notes: version.notes,
              createdAtMicros: Int64(version.createdAt.microsecondsSinceEpoch),
            ),
          ),
          activeVersionId: scene.activeVersionId,
        ),
      ),
      lastModifiedMicros: Int64(project.lastModified.microsecondsSinceEpoch),
    );
  }

  static StoryProject _fromDocument(StoryProjectDocument document) {
    return StoryProject(
      id: document.id,
      title: document.title,
      logline: document.logline,
      genre: document.genre,
      author: document.author,
      isSample: document.isSample,
      events: document.events
          .map(
            (event) => StoryEvent(
              id: event.id,
              title: event.title,
              description: event.description,
              beatId: event.hasBeatId() ? event.beatId : null,
              characters: event.characters.toList(),
              location: event.location,
              orderIndex: event.orderIndex,
              createdAt: _dateTime(event.createdAtMicros),
            ),
          )
          .toList(),
      scenes: document.scenes
          .map(
            (scene) => Scene(
              id: scene.id,
              beatId: scene.beatId,
              title: scene.title,
              timelineOrder: scene.timelineOrder,
              mappedEventIds: scene.mappedEventIds.toList(),
              versions: scene.versions
                  .map(
                    (version) => SceneVersion(
                      id: version.id,
                      versionNumber: version.versionNumber,
                      label: version.label,
                      slugline: version.slugline,
                      summary: version.summary,
                      scriptContent: version.scriptContent,
                      notes: version.notes,
                      createdAt: _dateTime(version.createdAtMicros),
                    ),
                  )
                  .toList(),
              activeVersionId: scene.hasActiveVersionId()
                  ? scene.activeVersionId
                  : null,
            ),
          )
          .toList(),
      lastModified: _dateTime(document.lastModifiedMicros),
    );
  }

  static DateTime _dateTime(Int64 micros) =>
      DateTime.fromMicrosecondsSinceEpoch(micros.toInt());
}
