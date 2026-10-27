import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/beat_model.dart';
import '../models/story_event.dart';
import '../models/scene_model.dart';
import '../models/story_project.dart';
import '../services/project_codec.dart';
import '../services/storage_service.dart';

class StoryProvider extends ChangeNotifier {
  StoryProject _project;
  String? _documentPath;
  bool _hasUnsavedChanges = false;
  int _changeVersion = 0;
  Future<void> _saveQueue = Future<void>.value();
  List<RecentDocument> _recentDocuments = [];
  List<ProjectMetadata> _recentProjects = [];
  bool _isLoading = false;
  bool _disposed = false;

  String? _selectedBeatId;
  String? _selectedSceneId;
  bool _isEventPoolOpen = true;
  String _eventSearchQuery = '';

  static const _uuid = Uuid();

  StoryProvider({StoryProject? initialProject, String? documentPath})
    : _project = initialProject ?? StoryProject.createSampleProject(),
      _documentPath = documentPath {
    refreshRecentDocuments();
  }

  StoryProject get project => _project;
  String? get documentPath => _documentPath;
  bool get hasUnsavedChanges => _hasUnsavedChanges;
  List<RecentDocument> get recentDocuments => _recentDocuments;
  List<ProjectMetadata> get recentProjects => _recentProjects;
  bool get isLoading => _isLoading;
  String? get selectedBeatId => _selectedBeatId;
  String? get selectedSceneId => _selectedSceneId;
  bool get isEventPoolOpen => _isEventPoolOpen;
  String get eventSearchQuery => _eventSearchQuery;

  Future<void> refreshRecentDocuments() async {
    final documents = await StorageService.listRecentDocuments();
    if (_disposed) return;
    _recentDocuments = documents;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void newDocument() {
    _project = StoryProject.createEmptyProject();
    _documentPath = null;
    _hasUnsavedChanges = false;
    _selectedBeatId = null;
    _selectedSceneId = null;
    notifyListeners();
  }

  Future<bool> openDocument(String path) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _saveQueue;
      _project = await StorageService.openDocument(path);
      _documentPath = path;
      _hasUnsavedChanges = false;
      _selectedBeatId = null;
      _selectedSceneId = null;
      await refreshRecentDocuments();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (error) {
      debugPrint('Failed to open BeatWork document: $error');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> saveDocument() async {
    final path = _documentPath;
    if (path == null) return false;
    try {
      await _saveQueue;
      await StorageService.saveDocumentToPath(_project, path);
      _hasUnsavedChanges = false;
      await refreshRecentDocuments();
      notifyListeners();
      return true;
    } catch (error) {
      debugPrint('Failed to save BeatWork document: $error');
      return false;
    }
  }

  Future<bool> saveDocumentAs({String? initialDirectory}) async {
    try {
      await _saveQueue;
      final path = await StorageService.saveDocumentAs(
        _project,
        initialDirectory: initialDirectory,
      );
      if (path == null) return false;
      _documentPath = path;
      _hasUnsavedChanges = false;
      await refreshRecentDocuments();
      notifyListeners();
      return true;
    } catch (error) {
      debugPrint('Failed to save BeatWork document as: $error');
      return false;
    }
  }

  Future<bool> openDocumentPicker() async {
    final path = await StorageService.pickDocumentPath();
    return path == null ? false : openDocument(path);
  }

  BeatDefinition? get selectedBeat {
    if (_selectedBeatId == null) return null;
    return BeatDefinition.getById(_selectedBeatId!);
  }

  Scene? get selectedScene {
    if (_selectedSceneId == null) return null;
    try {
      return _project.scenes.firstWhere((s) => s.id == _selectedSceneId);
    } catch (_) {
      return null;
    }
  }

  // --- Multi-Project Management ---

  Future<void> refreshRecentProjects() async {
    final list = await StorageService.listProjects();
    _recentProjects = list;
    notifyListeners();
  }

  /// Switches active screenplay to [projectId], saving current project first.
  Future<bool> switchProject(String projectId) async {
    if (projectId == _project.id) return true;

    _isLoading = true;
    notifyListeners();

    try {
      await StorageService.saveProject(_project);
      final loaded = await StorageService.loadProjectById(projectId);
      if (loaded != null) {
        _project = loaded;
        _selectedBeatId = null;
        _selectedSceneId = null;
        await refreshRecentProjects();
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Failed to switch project: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Creates a brand new screenplay project and sets it as the active project.
  Future<StoryProject> createNewProject({
    String title = 'Untitled Screenplay',
    String logline = '',
    String genre = 'Feature Film',
    String author = 'Screenwriter',
  }) async {
    _isLoading = true;
    notifyListeners();

    await StorageService.saveProject(_project);

    final newProj = StoryProject.createEmptyProject(
      title: title,
      logline: logline,
      genre: genre,
      author: author,
    );

    _project = newProj;
    _selectedBeatId = null;
    _selectedSceneId = null;

    await StorageService.saveProject(_project, setAsMostRecent: true);
    await refreshRecentProjects();

    _isLoading = false;
    notifyListeners();
    return newProj;
  }

  /// Duplicates the current screenplay project and switches to the copy.
  Future<StoryProject> duplicateCurrentProject({String? newTitle}) async {
    _isLoading = true;
    notifyListeners();

    await StorageService.saveProject(_project);

    final dup = await StorageService.duplicateProject(
      _project,
      newTitle: newTitle,
    );
    _project = dup;
    _selectedBeatId = null;
    _selectedSceneId = null;

    await refreshRecentProjects();

    _isLoading = false;
    notifyListeners();
    return dup;
  }

  /// Deletes a project by ID. If deleting active project, switches to the next most recent.
  Future<void> deleteProject(String projectId) async {
    _isLoading = true;
    notifyListeners();

    final isCurrent = projectId == _project.id;
    await StorageService.deleteProject(projectId);

    if (isCurrent) {
      final next = await StorageService.loadMostRecentProject();
      _project = next;
      _selectedBeatId = null;
      _selectedSceneId = null;
    }

    await refreshRecentProjects();

    _isLoading = false;
    notifyListeners();
  }

  /// Restores or loads the built-in sample project ("The Chronos Cipher").
  Future<void> loadSampleProject({bool asNewCopy = false}) async {
    _isLoading = true;
    notifyListeners();

    await StorageService.saveProject(_project);

    final sample = await StorageService.restoreSampleProject(
      asNewCopy: asNewCopy,
    );
    _project = sample;
    _selectedBeatId = null;
    _selectedSceneId = null;

    await refreshRecentProjects();

    _isLoading = false;
    notifyListeners();
  }

  // --- UI Layout and View Toggles ---

  void toggleEventPool() {
    _isEventPoolOpen = !_isEventPoolOpen;
    notifyListeners();
  }

  void setEventPoolOpen(bool open) {
    _isEventPoolOpen = open;
    notifyListeners();
  }

  void setEventSearchQuery(String query) {
    _eventSearchQuery = query;
    notifyListeners();
  }

  void selectBeat(String? beatId) {
    _selectedBeatId = beatId;
    if (beatId != null) {
      final beatScenes = _project.getScenesForBeat(beatId);
      _selectedSceneId = beatScenes.isNotEmpty ? beatScenes.first.id : null;
    } else {
      _selectedSceneId = null;
    }
    notifyListeners();
  }

  void selectScene(String? sceneId) {
    _selectedSceneId = sceneId;
    notifyListeners();
  }

  // --- Project Metadata ---

  void updateProjectMeta({
    String? title,
    String? logline,
    String? genre,
    String? author,
    String? authorEmail,
  }) {
    if (title != null) _project.title = title;
    if (logline != null) _project.logline = logline;
    if (genre != null) _project.genre = genre;
    if (author != null) _project.author = author;
    if (authorEmail != null) _project.authorEmail = authorEmail;
    _project.lastModified = DateTime.now();
    _save();
    notifyListeners();
  }

  // --- Events ---

  StoryEvent createEvent({
    required String title,
    String description = '',
    String? beatId,
    List<String>? characters,
    String location = '',
  }) {
    final newEvent = StoryEvent(
      id: _uuid.v4(),
      title: title,
      description: description,
      beatId: beatId,
      characters: characters ?? [],
      location: location,
      orderIndex: beatId != null ? _project.getEventsForBeat(beatId).length : 0,
    );

    _project.events.add(newEvent);
    _project.lastModified = DateTime.now();
    _save();
    notifyListeners();
    return newEvent;
  }

  void updateEvent(StoryEvent updatedEvent) {
    final idx = _project.events.indexWhere((e) => e.id == updatedEvent.id);
    if (idx != -1) {
      _project.events[idx] = updatedEvent;
      _project.lastModified = DateTime.now();
      _save();
      notifyListeners();
    }
  }

  void deleteEvent(String eventId) {
    _project.events.removeWhere((e) => e.id == eventId);
    for (final s in _project.scenes) {
      s.mappedEventIds.remove(eventId);
    }
    _project.lastModified = DateTime.now();
    _save();
    notifyListeners();
  }

  /// Assign an event to a specific beat (Drag and Drop core mechanic)
  void assignEventToBeat(String eventId, String beatId) {
    final event = _project.events.firstWhere((e) => e.id == eventId);
    if (event.beatId == beatId) return;

    final targetBeatEvents = _project.getEventsForBeat(beatId);
    event.beatId = beatId;
    event.orderIndex = targetBeatEvents.length;
    _project.lastModified = DateTime.now();
    _save();
    notifyListeners();
  }

  /// Unassign event back to the unassigned event pool
  void unassignEvent(String eventId) {
    final event = _project.events.firstWhere((e) => e.id == eventId);
    event.beatId = null;
    for (final s in _project.scenes) {
      s.mappedEventIds.remove(eventId);
    }
    _project.lastModified = DateTime.now();
    _save();
    notifyListeners();
  }

  void reorderEventsInBeat(String beatId, int oldIndex, int newIndex) {
    final beatEvents = _project.getEventsForBeat(beatId);
    if (oldIndex < 0 || oldIndex >= beatEvents.length) return;
    if (newIndex < 0 || newIndex > beatEvents.length) return;

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final moved = beatEvents.removeAt(oldIndex);
    beatEvents.insert(newIndex, moved);

    for (int i = 0; i < beatEvents.length; i++) {
      beatEvents[i].orderIndex = i;
    }

    _project.lastModified = DateTime.now();
    _save();
    notifyListeners();
  }

  // --- Scenes ---

  Scene createScene({
    required String beatId,
    required String title,
    String slugline = 'INT. NEW SCENE - DAY',
    List<String>? mappedEventIds,
  }) {
    final beatScenes = _project.getScenesForBeat(beatId);
    final scene = Scene(
      id: _uuid.v4(),
      beatId: beatId,
      title: title,
      timelineOrder: beatScenes.length,
      mappedEventIds: mappedEventIds ?? [],
    );

    scene.versions.first.slugline = slugline;
    scene.versions.first.summary = title;

    _project.scenes.add(scene);
    _selectedSceneId = scene.id;
    _project.lastModified = DateTime.now();
    _save();
    notifyListeners();
    return scene;
  }

  void updateScene(Scene updatedScene) {
    final idx = _project.scenes.indexWhere((s) => s.id == updatedScene.id);
    if (idx != -1) {
      _project.scenes[idx] = updatedScene;
      _project.lastModified = DateTime.now();
      _save();
      notifyListeners();
    }
  }

  void deleteScene(String sceneId) {
    _project.scenes.removeWhere((s) => s.id == sceneId);
    if (_selectedSceneId == sceneId) {
      final beatScenes = _selectedBeatId != null
          ? _project.getScenesForBeat(_selectedBeatId!)
          : <Scene>[];
      _selectedSceneId = beatScenes.isNotEmpty ? beatScenes.first.id : null;
    }
    _project.lastModified = DateTime.now();
    _save();
    notifyListeners();
  }

  void reorderScenesInBeat(String beatId, int oldIndex, int newIndex) {
    final beatScenes = _project.getScenesForBeat(beatId);
    if (oldIndex < 0 || oldIndex >= beatScenes.length) return;
    if (newIndex < 0 || newIndex > beatScenes.length) return;

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final moved = beatScenes.removeAt(oldIndex);
    beatScenes.insert(newIndex, moved);

    for (int i = 0; i < beatScenes.length; i++) {
      beatScenes[i].timelineOrder = i;
    }

    _project.lastModified = DateTime.now();
    _save();
    notifyListeners();
  }

  void toggleEventMappingForScene(String sceneId, String eventId) {
    final scene = _project.scenes.firstWhere((s) => s.id == sceneId);
    if (scene.mappedEventIds.contains(eventId)) {
      scene.mappedEventIds.remove(eventId);
    } else {
      scene.mappedEventIds.add(eventId);
    }
    _project.lastModified = DateTime.now();
    _save();
    notifyListeners();
  }

  // --- Scene Versions ---

  SceneVersion createNextSceneVersion(
    String sceneId, {
    String? label,
    String? slugline,
    String? summary,
    String? scriptContent,
    String? notes,
  }) {
    final scene = _project.scenes.firstWhere((s) => s.id == sceneId);
    final newVersion = scene.createNewVersion(
      label: label,
      slugline: slugline,
      summary: summary,
      scriptContent: scriptContent,
      notes: notes,
    );
    _project.lastModified = DateTime.now();
    _save();
    notifyListeners();
    return newVersion;
  }

  void setActiveSceneVersion(String sceneId, String versionId) {
    final scene = _project.scenes.firstWhere((s) => s.id == sceneId);
    if (scene.versions.any((v) => v.id == versionId)) {
      scene.activeVersionId = versionId;
      _project.lastModified = DateTime.now();
      _save();
      notifyListeners();
    }
  }

  void updateActiveVersionContent(
    String sceneId, {
    String? label,
    String? slugline,
    String? summary,
    String? scriptContent,
    String? notes,
  }) {
    final scene = _project.scenes.firstWhere((s) => s.id == sceneId);
    final active = scene.activeVersion;

    if (label != null) active.label = label;
    if (slugline != null) active.slugline = slugline;
    if (summary != null) active.summary = summary;
    if (scriptContent != null) active.scriptContent = scriptContent;
    if (notes != null) active.notes = notes;

    _project.lastModified = DateTime.now();
    _save();
    notifyListeners();
  }

  void _save() {
    _hasUnsavedChanges = true;
    final version = ++_changeVersion;
    final path = _documentPath;
    if (path == null) return;
    final snapshot = ProjectCodec.decode(ProjectCodec.encode(_project));

    _saveQueue = _saveQueue
        .then((_) async {
          await StorageService.saveDocumentToPath(snapshot, path);
          if (version == _changeVersion) {
            _hasUnsavedChanges = false;
            notifyListeners();
          }
        })
        .catchError((Object error) {
          debugPrint('Autosave failed for $path: $error');
        });
  }
}
