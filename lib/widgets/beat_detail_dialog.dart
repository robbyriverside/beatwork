import 'package:flutter/material.dart';
import '../models/beat_model.dart';
import '../models/scene_model.dart';
import '../models/story_event.dart';
import '../state/story_provider.dart';
import '../theme/app_theme.dart';
import 'event_card.dart';
import 'event_dialog.dart';
import 'scene_editor_view.dart';

class BeatDetailDialog extends StatefulWidget {
  final BeatDefinition beat;
  final StoryProvider provider;

  const BeatDetailDialog({
    super.key,
    required this.beat,
    required this.provider,
  });

  static Future<void> show(
    BuildContext context, {
    required BeatDefinition beat,
    required StoryProvider provider,
  }) {
    provider.selectBeat(beat.id);
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => BeatDetailDialog(beat: beat, provider: provider),
    );
  }

  @override
  State<BeatDetailDialog> createState() => _BeatDetailDialogState();
}

class _BeatDetailDialogState extends State<BeatDetailDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, initialIndex: 1, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        final selectedScene = widget.provider.selectedScene;

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppTheme.borderHighlight, width: 1.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.92,
              height: MediaQuery.of(context).size.height * 0.90,
              child: Column(
                children: [
                  // Header
                  _buildHeader(beatEvents.length, beatScenes.length),

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
                                            const Icon(Icons.bolt, size: 16),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Events (${beatEvents.length})',
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
                                            Text(
                                              'Timeline (${beatScenes.length})',
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
                                      _buildBeatEventsView(beatEvents),

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

  Widget _buildBeatEventsView(List<StoryEvent> beatEvents) {
    return Column(
      children: [
        // Guidance banner: "Initially a list of events in no particular order. Usually 3 to 5 events."
        Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline,
                size: 16,
                color: AppTheme.goldAccent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${beatEvents.length} events assigned. Usually 3 to 5 events belong in this beat.',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
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
                            initialEvent: ev,
                          );
                          if (updated != null) {
                            widget.provider.updateEvent(updated);
                          }
                        },
                        onDelete: () => widget.provider.deleteEvent(ev.id),
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
              label: const Text('Add Event to this Beat'),
              onPressed: () async {
                final newEv = await EventDialog.show(
                  context,
                  initialBeatId: widget.beat.id,
                );
                if (newEv != null) {
                  widget.provider.createEvent(
                    title: newEv.title,
                    description: newEv.description,
                    beatId: widget.beat.id,
                    characters: newEv.characters,
                    location: newEv.location,
                  );
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBeatTimelineView(List<Scene> beatScenes) {
    return Column(
      children: [
        // Timeline Header Explanation
        Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppTheme.border),
          ),
          child: const Row(
            children: [
              Icon(Icons.route, size: 16, color: AppTheme.cyanAccent),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'The beat timeline is the sequence of scenes executing this beat.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Timeline Scene List
        Expanded(
          child: beatScenes.isEmpty
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
                        const Text(
                          'No Scenes in Beat Timeline',
                          style: TextStyle(
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
              : ReorderableListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  itemCount: beatScenes.length,
                  onReorder: (oldIndex, newIndex) {
                    widget.provider.reorderScenesInBeat(
                      widget.beat.id,
                      oldIndex,
                      newIndex,
                    );
                  },
                  itemBuilder: (context, index) {
                    final sc = beatScenes[index];
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
                            color: isSelected
                                ? AppTheme.goldAccent
                                : AppTheme.border,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 2,
                          ),
                          leading: CircleAvatar(
                            radius: 12,
                            backgroundColor: isSelected
                                ? AppTheme.goldAccent
                                : AppTheme.surfaceElevated,
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.black
                                    : AppTheme.textSecondary,
                              ),
                            ),
                          ),
                          title: Text(
                            sc.title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w600,
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
                                  Text(
                                    '${sc.mappedEventIds.length} Events Mapped',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.cyanAccent,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'v${activeVer.versionNumber} (${sc.versions.length} drafts)',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, size: 16),
                            padding: EdgeInsets.zero,
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text(
                                  'Delete Scene',
                                  style: TextStyle(
                                    color: AppTheme.crimsonAccent,
                                  ),
                                ),
                              ),
                            ],
                            onSelected: (val) {
                              if (val == 'delete') {
                                widget.provider.deleteScene(sc.id);
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

  void _promptNewScene(BuildContext context) {
    final titleCtrl = TextEditingController(text: 'New Scene');
    final sluglineCtrl = TextEditingController(text: 'INT. NEW LOCATION - DAY');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Scene to Beat Timeline'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Scene Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: sluglineCtrl,
              decoration: const InputDecoration(
                labelText: 'Slugline / Scene Heading',
                hintText: 'e.g. INT. POLICE STATION - NIGHT',
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final title = titleCtrl.text.trim();
              if (title.isNotEmpty) {
                widget.provider.createScene(
                  beatId: widget.beat.id,
                  title: title,
                  slugline: sluglineCtrl.text.trim().toUpperCase(),
                );
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Add Scene'),
          ),
        ],
      ),
    );
  }
}
