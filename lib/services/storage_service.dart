import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/story_project.dart';

/// StorageService provides robust multi-project persistence for BeatWork screenplays.
///
/// Features:
/// - Screenplays stored independently in `<appDocs>/beatwork_projects/<id>.json`.
/// - `manifest.json` tracks the `mostRecentProjectId` and index of `ProjectMetadata`.
/// - Automatic migration of legacy single-project files.
/// - The sample project ("The Chronos Cipher") is saved and maintained as an available template.
/// - Loads the most recently opened or modified project on app startup.
class StorageService {
  static const String _projectsDirName = 'beatwork_projects';
  static const String _manifestFileName = 'manifest.json';
  static const String _sampleProjectId = 'sample-chronos-cipher';

  /// Optional override for testing environments
  @visibleForTesting
  static Directory? overrideDirectory;

  static Future<Directory> _getProjectsDirectory() async {
    Directory baseDir;
    if (overrideDirectory != null) {
      baseDir = overrideDirectory!;
    } else {
      try {
        baseDir = await getApplicationDocumentsDirectory();
      } catch (e) {
        debugPrint('getApplicationDocumentsDirectory failed or unsupported (e.g. in tests): $e');
        baseDir = Directory.systemTemp.createTempSync('beatwork_storage_');
      }
    }

    final projectsDir = Directory('${baseDir.path}/$_projectsDirName');
    if (!await projectsDir.exists()) {
      await projectsDir.create(recursive: true);
    }
    return projectsDir;
  }

  static Future<File> _getManifestFile() async {
    final dir = await _getProjectsDirectory();
    return File('${dir.path}/$_manifestFileName');
  }

  static Future<File> _getProjectFile(String id) async {
    final dir = await _getProjectsDirectory();
    return File('${dir.path}/$id.json');
  }

  /// Migrates legacy `beatwork_project.json` into the multi-project directory if it exists.
  static Future<void> _migrateLegacyProjectIfExists(Directory projectsDir) async {
    try {
      final baseDir = projectsDir.parent;
      final legacyFile = File('${baseDir.path}/beatwork_project.json');
      if (await legacyFile.exists()) {
        final content = await legacyFile.readAsString();
        final Map<String, dynamic> data = jsonDecode(content);
        final project = StoryProject.fromJson(data);
        final newFile = File('${projectsDir.path}/${project.id}.json');
        if (!await newFile.exists()) {
          await newFile.writeAsString(content);
        }
        await legacyFile.delete();
        debugPrint('Migrated legacy project "${project.title}" to ${project.id}.json');
      }
    } catch (e) {
      debugPrint('Legacy project migration check skipped or failed: $e');
    }
  }

  /// Ensures the built-in sample project template exists in storage.
  static Future<StoryProject> ensureSampleProjectExists() async {
    final sampleFile = await _getProjectFile(_sampleProjectId);
    if (await sampleFile.exists()) {
      try {
        final content = await sampleFile.readAsString();
        return StoryProject.fromJson(jsonDecode(content));
      } catch (e) {
        debugPrint('Error reading existing sample project: $e');
      }
    }

    final sample = StoryProject.createSampleProject(id: _sampleProjectId);
    await saveProject(sample, setAsMostRecent: false);
    return sample;
  }

  /// Loads the most recently opened or modified project.
  /// If no projects exist, initializes the sample project and returns it.
  static Future<StoryProject> loadMostRecentProject() async {
    try {
      final dir = await _getProjectsDirectory();
      await _migrateLegacyProjectIfExists(dir);
      await ensureSampleProjectExists();

      final manifestFile = await _getManifestFile();
      String? mostRecentId;

      if (await manifestFile.exists()) {
        try {
          final manifestContent = await manifestFile.readAsString();
          final Map<String, dynamic> manifest = jsonDecode(manifestContent);
          mostRecentId = manifest['mostRecentProjectId'] as String?;
        } catch (e) {
          debugPrint('Error reading manifest: $e');
        }
      }

      // If we have a target most recent project id, try loading it
      if (mostRecentId != null) {
        final project = await loadProjectById(mostRecentId, updateRecent: false);
        if (project != null) {
          return project;
        }
      }

      // Otherwise find the project with the newest lastModified date
      final projects = await listProjects();
      if (projects.isNotEmpty) {
        final project = await loadProjectById(projects.first.id);
        if (project != null) {
          return project;
        }
      }

      // Fallback: load or create the sample project
      final sample = await ensureSampleProjectExists();
      await _updateManifest(mostRecentId: sample.id, updatedProject: sample);
      return sample;
    } catch (e) {
      debugPrint('Failed to load most recent project: $e');
      return StoryProject.createSampleProject(id: _sampleProjectId);
    }
  }

  /// Loads a specific project by its ID and marks it as the most recent.
  static Future<StoryProject?> loadProjectById(String id, {bool updateRecent = true}) async {
    try {
      final file = await _getProjectFile(id);
      if (await file.exists()) {
        final content = await file.readAsString();
        final Map<String, dynamic> data = jsonDecode(content);
        final project = StoryProject.fromJson(data);

        if (updateRecent) {
          await _updateManifest(mostRecentId: project.id, updatedProject: project);
        }
        return project;
      }
    } catch (e) {
      debugPrint('Failed to load project $id: $e');
    }
    return null;
  }

  /// Saves a project to `<appDocs>/beatwork_projects/<id>.json` and updates the manifest.
  static Future<void> saveProject(StoryProject project, {bool setAsMostRecent = true}) async {
    try {
      final file = await _getProjectFile(project.id);
      final jsonStr = jsonEncode(project.toJson());
      await file.writeAsString(jsonStr);

      await _updateManifest(
        mostRecentId: setAsMostRecent ? project.id : null,
        updatedProject: project,
      );
    } catch (e) {
      debugPrint('Failed to save project ${project.id}: $e');
    }
  }

  /// Lists all screenplays available in storage, ordered by last modified descending.
  static Future<List<ProjectMetadata>> listProjects() async {
    final List<ProjectMetadata> list = [];
    try {
      final dir = await _getProjectsDirectory();
      final entities = dir.listSync();

      for (final entity in entities) {
        if (entity is File &&
            entity.path.endsWith('.json') &&
            !entity.path.endsWith(_manifestFileName)) {
          try {
            final content = await entity.readAsString();
            final Map<String, dynamic> data = jsonDecode(content);
            final meta = ProjectMetadata(
              id: data['id'] as String,
              title: data['title'] as String,
              logline: data['logline'] as String? ?? '',
              genre: data['genre'] as String? ?? 'Feature Film',
              author: data['author'] as String? ?? 'Screenwriter',
              eventCount: (data['events'] as List<dynamic>?)?.length ?? 0,
              sceneCount: (data['scenes'] as List<dynamic>?)?.length ?? 0,
              isSample: data['isSample'] as bool? ?? false,
              lastModified: data['lastModified'] != null
                  ? DateTime.tryParse(data['lastModified'] as String) ?? DateTime.now()
                  : DateTime.now(),
            );
            list.add(meta);
          } catch (e) {
            debugPrint('Failed to parse metadata from ${entity.path}: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to list projects: $e');
    }

    list.sort((a, b) => b.lastModified.compareTo(a.lastModified));
    return list;
  }

  /// Deletes a project from storage.
  /// If it was the most recent, returns the ID of the new most recent project.
  static Future<String?> deleteProject(String id) async {
    try {
      final file = await _getProjectFile(id);
      if (await file.exists()) {
        await file.delete();
      }

      final manifestFile = await _getManifestFile();
      String? mostRecentId;
      if (await manifestFile.exists()) {
        try {
          final manifestContent = await manifestFile.readAsString();
          final Map<String, dynamic> manifest = jsonDecode(manifestContent);
          mostRecentId = manifest['mostRecentProjectId'] as String?;
        } catch (_) {}
      }

      final remaining = await listProjects();
      String? newMostRecentId = mostRecentId;

      if (mostRecentId == id) {
        newMostRecentId = remaining.isNotEmpty ? remaining.first.id : null;
      }

      await _writeManifest(newMostRecentId, remaining);
      return newMostRecentId;
    } catch (e) {
      debugPrint('Failed to delete project $id: $e');
      return null;
    }
  }

  /// Duplicates an existing project under a new ID and saves it as the active screenplay.
  static Future<StoryProject> duplicateProject(StoryProject project, {String? newTitle}) async {
    final duplicate = project.duplicate(newTitle: newTitle);
    await saveProject(duplicate, setAsMostRecent: true);
    return duplicate;
  }

  /// Restores or creates a fresh copy of the sample project.
  static Future<StoryProject> restoreSampleProject({bool asNewCopy = false}) async {
    final sample = StoryProject.createSampleProject(
      id: asNewCopy ? null : _sampleProjectId,
    );
    if (asNewCopy) {
      sample.title = 'The Chronos Cipher (Working Copy)';
      sample.isSample = false;
    }
    await saveProject(sample, setAsMostRecent: true);
    return sample;
  }

  static Future<void> _updateManifest({
    String? mostRecentId,
    StoryProject? updatedProject,
  }) async {
    final projects = await listProjects();
    final manifestFile = await _getManifestFile();

    String? currentRecentId = mostRecentId;
    if (currentRecentId == null && await manifestFile.exists()) {
      try {
        final content = await manifestFile.readAsString();
        final Map<String, dynamic> manifest = jsonDecode(content);
        currentRecentId = manifest['mostRecentProjectId'] as String?;
      } catch (_) {}
    }

    if (currentRecentId == null && projects.isNotEmpty) {
      currentRecentId = projects.first.id;
    }

    await _writeManifest(currentRecentId, projects);
  }

  static Future<void> _writeManifest(
    String? mostRecentId,
    List<ProjectMetadata> projects,
  ) async {
    try {
      final manifestFile = await _getManifestFile();
      final manifestData = {
        'mostRecentProjectId': mostRecentId,
        'projects': projects.map((p) => p.toJson()).toList(),
      };
      await manifestFile.writeAsString(jsonEncode(manifestData));
    } catch (e) {
      debugPrint('Failed to write manifest: $e');
    }
  }

  /// Legacy helper for backwards compatibility.
  static Future<StoryProject?> loadProject() async {
    return loadMostRecentProject();
  }
}
