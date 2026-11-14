import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/beat_model.dart';
import '../models/scene_model.dart';
import '../models/story_event.dart';
import '../state/story_provider.dart';
import '../theme/app_theme.dart';
import 'event_card.dart';
import 'event_dialog.dart';
import 'scene_editor_view.dart';
import 'slugline_fields.dart';

class BeatDetailDialog extends StatefulWidget {
  final BeatDefinition beat;
  final StoryProvider provider;
  final VoidCallback? onSave;
  final VoidCallback? onSaveAs;

  const BeatDetailDialog({
    super.key,
    required this.beat,
    required this.provider,
    this.onSave,
    this.onSaveAs,
  });

  static Future<void> show(
    BuildContext context, {
    required BeatDefinition beat,
    required StoryProvider provider,
    VoidCallback? onSave,
    VoidCallback? onSaveAs,
  }) {
    provider.selectBeat(beat.id);
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => BeatDetailDialog(
        beat: beat,
        provider: provider,
        onSave: onSave,
        onSaveAs: onSaveAs,
      ),
    );
  }

  @override
  State<BeatDetailDialog> createState() => _BeatDetailDialogState();
}

class _BeatDetailDialogState extends State<BeatDetailDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _sceneBodyFocusNode = FocusNode();
  bool _showUnusedScenes = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, initialIndex: 1, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _sceneBodyFocusNode.dispose();
    super.dispose();
  }

  Future<void> _addEventToBeat() async {
    final newEvent = await EventDialog.show(
      context,
      beats: widget.provider.project.beatSheet.beats,
      initialBeatId: widget.beat.id,
      onSaveAndContinue: (event, isEditing) {
        if (isEditing) {
          widget.provider.updateEvent(event);
        } else {
          widget.provider.createEvent(
            title: event.title,
            description: event.description,
            beatId: widget.beat.id,
            characters: event.characters,
            location: event.location,
          );
        }
      },
    );
    if (newEvent == null) return;

    widget.provider.createEvent(
      title: newEvent.title,
      description: newEvent.description,
      beatId: widget.beat.id,
      characters: newEvent.characters,
      location: newEvent.location,
    );
  }

  Future<void> _confirmDeleteScene(Scene scene) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Scene?'),
        content: Text(
          'Permanently delete "${scene.title}" and all its versions? This cannot be undone.',
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete Scene'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    if (!scene.isUnused) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only unused scenes can be deleted.')),
      );
      return;
    }
    widget.provider.deleteScene(scene.id);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.provider,
      builder: (context, _) {
        final beatEvents = widget.provider.project.getEventsForBeat(
          widget.beat.id,
        );
        final beatScenes = widget.provider.project.getScenesForBeat(
          widget.beat.id,
        );
        final activeSceneCount = beatScenes
            .where((scene) => !scene.isUnused)
            .length;
        final selectedScene = widget.provider.selectedScene;

        return CallbackShortcuts(
          bindings: {
            SingleActivator(
              LogicalKeyboardKey.keyE,
              meta: Platform.isMacOS,
              control: !Platform.isMacOS,
            ): _addEventToBeat,
            if (widget.onSave != null)
              SingleActivator(
                LogicalKeyboardKey.keyS,
                meta: Platform.isMacOS,
                control: !Platform.isMacOS,
              ): widget.onSave!,
            if (widget.onSaveAs != null)
              SingleActivator(
                LogicalKeyboardKey.keyS,
                meta: Platform.isMacOS,
                control: !Platform.isMacOS,
                shift: true,
              ): widget.onSaveAs!,
          },
          child: Focus(
            autofocus: true,
            child: Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 24,
              ),
              backgroundColor: AppTheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(
                  color: AppTheme.borderHighlight,
                  width: 1.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.92,
                  height: MediaQuery.of(context).size.height * 0.90,
                  child: Column(
                    children: [
                      // Header
                      _buildHeader(beatEvents.length, activeSceneCount),

                      // Main Content: Split View
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Left Panel: Events & Scene Timeline tabs
                            SizedBox(
                              width: 380,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: AppTheme.surfaceElevated,
                                  border: Border(
                                    right: BorderSide(color: AppTheme.border),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    // Tabs
                                    Container(
                                      color: AppTheme.surface,
                                      child: TabBar(
                                        controller: _tabController,
                                        labelColor: AppTheme.goldAccent,
                                        unselectedLabelColor:
                                            AppTheme.textSecondary,
                                        indicatorColor: AppTheme.goldAccent,
                                        tabs: [
                                          Tab(
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                const Icon(
                                                  Icons.bolt,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 6),
                                                Flexible(
                                                  child: Text(
                                                    'Events (${beatEvents.length})',
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Tab(
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                const Icon(
                                                  Icons.timeline,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 6),
                                                Flexible(
                                                  child: Text(
                                                    'Timeline ($activeSceneCount)',
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Tab Views
                                    Expanded(
                                      child: TabBarView(
                                        controller: _tabController,
                                        children: [
                                          // 1. Beat Events View
                                          _buildBeatEventsView(
                                            beatEvents,
                                            activeSceneCount,
                                          ),

                                          // 2. Beat Timeline View (Series of scenes)
                                          _buildBeatTimelineView(beatScenes),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Right Panel: Scene Screenplay Editor & Multi-Version Manager
                            Expanded(
                              child: selectedScene != null
                                  ? SceneEditorView(
                                      scene: selectedScene,
                                      beat: widget.beat,
                                      provider: widget.provider,
                                      bodyFocusNode: _sceneBodyFocusNode,
                                    )
                                  : _buildNoScenePlaceholder(beatScenes),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(int eventCount, int sceneCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        border: const Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.beat.act.accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: widget.beat.act.accentColor),
                ),
                child: Text(
                  'BEAT ${widget.beat.number}: ${widget.beat.act.title}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: widget.beat.act.accentColor,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                widget.beat.icon,
                size: 20,
                color: widget.beat.act.accentColor,
              ),
              const SizedBox(width: 8),
              Text(
                widget.beat.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Text(
                  '${widget.beat.targetPage} (${widget.beat.percentage})',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Close Workspace',
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Guidance prompt
          Text(
            widget.beat.guidance,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstimateHint({
    required int count,
    required String singular,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Estimate: $count $singular${count == 1 ? '' : 's'}.',
              style: const TextStyle(
                fontSize: 11.5,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBeatEventsView(List<StoryEvent> beatEvents, int sceneCount) {
    final estimate = widget.beat.estimatedSceneCount;
    final eventEstimate = sceneCount > estimate ? sceneCount : estimate;
    return Column(
      children: [
        _buildEstimateHint(
          count: eventEstimate,
          singular: 'event',
          icon: Icons.bolt,
          color: AppTheme.goldAccent,
        ),
        // Events List (Reorderable / in no particular order)
        Expanded(
          child: beatEvents.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.post_add,
                          size: 36,
                          color: AppTheme.textMuted,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No Events In This Beat Yet',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Drag events here from the Event Pool or add a new event below.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  itemCount: beatEvents.length,
                  onReorder: (oldIndex, newIndex) {
                    widget.provider.reorderEventsInBeat(
                      widget.beat.id,
                      oldIndex,
                      newIndex,
                    );
                  },
                  itemBuilder: (context, index) {
                    final ev = beatEvents[index];
                    return KeyedSubtree(
                      key: ValueKey(ev.id),
                      child: EventCard(
                        event: ev,
                        onEdit: () async {
                          final updated = await EventDialog.show(
                            context,
                            beats: widget.provider.project.beatSheet.beats,
                            initialEvent: ev,
                            onSaveAndContinue: (event, isEditing) {
                              if (isEditing) {
                                widget.provider.updateEvent(event);
                              } else {
                                widget.provider.createEvent(
                                  title: event.title,
                                  description: event.description,
                                  beatId: event.beatId,
                                  characters: event.characters,
                                  location: event.location,
                                );
                              }
                            },
                          );
                          if (updated != null) {
                            if (updated.id.isEmpty) {
                              widget.provider.createEvent(
                                title: updated.title,
                                description: updated.description,
                                beatId: updated.beatId,
                                characters: updated.characters,
                                location: updated.location,
                              );
                            } else {
                              widget.provider.updateEvent(updated);
                            }
                          }
                        },
                        onUnassign: () => widget.provider.unassignEvent(ev.id),
                        enableDrag: false,
                      ),
                    );
                  },
                ),
        ),

        // Add event button
        Padding(
          padding: const EdgeInsets.all(10),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Event to this Beat  (%E)'),
              onPressed: _addEventToBeat,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBeatTimelineView(List<Scene> beatScenes) {
    final sceneEstimate = widget.beat.estimatedSceneCount;
    final activeScenes = beatScenes.where((scene) => !scene.isUnused).toList();
    final unusedScenes = beatScenes.where((scene) => scene.isUnused).toList();
    final activeSceneCount = activeScenes.length;
    return Column(
      children: [
        _buildEstimateHint(
          count: sceneEstimate,
          singular: 'scene',
          icon: Icons.route,
          color: AppTheme.cyanAccent,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () =>
                setState(() => _showUnusedScenes = !_showUnusedScenes),
            child: Text(
              _showUnusedScenes ? 'Hide unused scenes' : 'Show unused scenes',
            ),
          ),
        ),

        // Timeline Scene List
        Expanded(
          child:
              beatScenes.isEmpty || (activeScenes.isEmpty && !_showUnusedScenes)
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.movie_creation_outlined,
                          size: 36,
                          color: AppTheme.textMuted,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          beatScenes.isNotEmpty
                              ? 'No visible scenes'
                              : 'No Scenes in Beat Timeline',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Add scenes to translate beat events into playable drama.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    if (activeScenes.isNotEmpty)
                      Expanded(
                        child: _buildSceneList(
                          activeScenes,
                          0,
                          isUnused: false,
                        ),
                      ),
                    if (_showUnusedScenes && unusedScenes.isNotEmpty)
                      Expanded(
                        child: _buildSceneList(
                          unusedScenes,
                          activeSceneCount,
                          isUnused: true,
                        ),
                      ),
                  ],
                ),
        ),

        // Add Scene Button
        Padding(
          padding: const EdgeInsets.all(10),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Scene to Timeline'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.cyanAccent,
                foregroundColor: Colors.black,
              ),
              onPressed: () => _promptNewScene(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSceneList(
    List<Scene> scenes,
    int indexOffset, {
    required bool isUnused,
  }) {
    return ReorderableListView.builder(
      key: ValueKey(isUnused ? 'unused-scenes-list' : 'active-scenes-list'),
      primary: false,
      reverse: isUnused,
      buildDefaultDragHandles: false,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      itemCount: scenes.length,
      onReorder: (oldIndex, newIndex) {
        widget.provider.reorderScenesInBeat(
          widget.beat.id,
          (isUnused ? scenes.length - 1 - oldIndex : oldIndex) + indexOffset,
          (isUnused ? scenes.length - newIndex : newIndex) + indexOffset,
        );
      },
      itemBuilder: (context, index) {
        final sceneIndex = isUnused ? scenes.length - 1 - index : index;
        final sc = scenes[sceneIndex];
        final isSelected = widget.provider.selectedSceneId == sc.id;
        final activeVer = sc.activeVersion;

        return KeyedSubtree(
          key: ValueKey(sc.id),
          child: Container(
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.goldAccent.withOpacity(0.12)
                  : AppTheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? AppTheme.goldAccent : AppTheme.border,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 2,
              ),
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ReorderableDragStartListener(
                    index: index,
                    child: const Tooltip(
                      message: 'Reorder scene',
                      child: Icon(Icons.drag_handle, size: 20),
                    ),
                  ),
                  const SizedBox(width: 6),
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: isSelected
                        ? AppTheme.goldAccent
                        : AppTheme.surfaceElevated,
                    child: Text(
                      '${sceneIndex + indexOffset + 1}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.black
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              title: Text(
                sc.title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected
                      ? AppTheme.goldAccent
                      : AppTheme.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (sc.isUnused)
                    const Text(
                      'UNUSED',
                      style: TextStyle(
                        color: AppTheme.crimsonAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  Text(
                    activeVer.slugline,
                    style: const TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${sc.mappedEventIds.length} Events Mapped',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppTheme.cyanAccent,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'v${activeVer.versionNumber} (${sc.versions.length} drafts)',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
              trailing: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 16),
                padding: EdgeInsets.zero,
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'unused',
                    child: Text(
                      sc.isUnused ? 'Mark as Used' : 'Mark as Unused',
                    ),
                  ),
                  if (sc.isUnused)
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Delete Scene',
                        style: TextStyle(color: AppTheme.crimsonAccent),
                      ),
                    ),
                ],
                onSelected: (val) {
                  if (val == 'unused') {
                    widget.provider.setSceneUnused(sc.id, !sc.isUnused);
                  }
                  if (val == 'delete') {
                    _confirmDeleteScene(sc);
                  }
                },
              ),
              onTap: () {
                widget.provider.selectScene(sc.id);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoScenePlaceholder(List<Scene> beatScenes) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.movie_filter_outlined,
            size: 48,
            color: AppTheme.textMuted.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Select a Scene to Write or Edit',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Pick a scene from the beat timeline on the left, or create a new scene.',
            style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Create New Scene'),
            onPressed: () => _promptNewScene(context),
          ),
        ],
      ),
    );
  }

  Future<void> _promptNewScene(BuildContext context) async {
    final previousSceneId = widget.provider.selectedSceneId;
    await showDialog<void>(
      context: context,
      builder: (context) =>
          _NewSceneDialog(beat: widget.beat, provider: widget.provider),
    );
    if (!mounted || widget.provider.selectedSceneId == previousSceneId) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _sceneBodyFocusNode.requestFocus();
    });
  }
}

class _NewSceneDialog extends StatefulWidget {
  final BeatDefinition beat;
  final StoryProvider provider;

  const _NewSceneDialog({required this.beat, required this.provider});

  @override
  State<_NewSceneDialog> createState() => _NewSceneDialogState();
}

class _NewSceneDialogState extends State<_NewSceneDialog> {
  final _titleController = TextEditingController();
  final _titleFocusNode = FocusNode();
  final _locationFocusNode = FocusNode();
  String _slugline = 'INT. - DAY';

  @override
  void dispose() {
    _titleController.dispose();
    _titleFocusNode.dispose();
    _locationFocusNode.dispose();
    super.dispose();
  }

  void _addScene() {
    final title = _titleController.text.trim();
    if (title.isNotEmpty) {
      widget.provider.createScene(
        beatId: widget.beat.id,
        title: title,
        slugline: _slugline,
      );
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Scene to Beat Timeline'),
      content: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const ValueKey('new-scene-title-field'),
              controller: _titleController,
              focusNode: _titleFocusNode,
              autofocus: true,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _locationFocusNode.requestFocus(),
              decoration: const InputDecoration(labelText: 'Scene Title'),
            ),
            const SizedBox(height: 12),
            SluglineFields(
              project: widget.provider.project,
              slugline: _slugline,
              locationFocusNode: _locationFocusNode,
              onChanged: (value) => _slugline = value,
              onLocationSubmitted: _addScene,
            ),
          ],
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _addScene, child: const Text('Add Scene')),
      ],
    );
  }
}
