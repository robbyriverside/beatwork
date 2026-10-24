import 'package:flutter/material.dart';
import 'models/story_project.dart';
import 'services/storage_service.dart';
import 'state/story_provider.dart';
import 'theme/app_theme.dart';
import 'widgets/beat_board_view.dart';
import 'widgets/beat_detail_dialog.dart';
import 'widgets/event_dialog.dart';
import 'widgets/event_pool_sidebar.dart';
import 'widgets/export_dialog.dart';
import 'widgets/script_reader_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final savedProject = await StorageService.loadProject();

  runApp(BeatWorkApp(initialProject: savedProject));
}

class BeatWorkApp extends StatelessWidget {
  final StoryProject? initialProject;

  const BeatWorkApp({super.key, this.initialProject});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BeatWork - Save the Cat Screenplay Beats',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: BeatWorkHomeScreen(initialProject: initialProject),
    );
  }
}

enum AppViewMode {
  beatSheet('Beat Sheet Board', Icons.dashboard_outlined),
  timelineReader('Collected Script Timeline', Icons.auto_stories_outlined);

  final String label;
  final IconData icon;
  const AppViewMode(this.label, this.icon);
}

class BeatWorkHomeScreen extends StatefulWidget {
  final StoryProject? initialProject;

  const BeatWorkHomeScreen({super.key, this.initialProject});

  @override
  State<BeatWorkHomeScreen> createState() => _BeatWorkHomeScreenState();
}

class _BeatWorkHomeScreenState extends State<BeatWorkHomeScreen> {
  late StoryProvider _provider;
  AppViewMode _viewMode = AppViewMode.beatSheet;

  @override
  void initState() {
    super.initState();
    _provider = StoryProvider(
      initialProject: widget.initialProject ?? StoryProject.createSampleProject(),
    );
  }

  void _openProjectSettings(BuildContext context) {
    final titleCtrl = TextEditingController(text: _provider.project.title);
    final loglineCtrl = TextEditingController(text: _provider.project.logline);
    final genreCtrl = TextEditingController(text: _provider.project.genre);
    final authorCtrl = TextEditingController(text: _provider.project.author);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.movie_filter_outlined, color: AppTheme.goldAccent),
            SizedBox(width: 8),
            Text('Screenplay Project Settings'),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Screenplay Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: loglineCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Logline / Premise',
                  hintText: 'A one-sentence summary with protagonist, conflict, and stakes.',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: genreCtrl,
                      decoration: const InputDecoration(labelText: 'Genre / Format'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: authorCtrl,
                      decoration: const InputDecoration(labelText: 'Screenwriter'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _provider.updateProjectMeta(
                title: titleCtrl.text.trim(),
                logline: loglineCtrl.text.trim(),
                genre: genreCtrl.text.trim(),
                author: authorCtrl.text.trim(),
              );
              Navigator.of(ctx).pop();
            },
            child: const Text('Save Details'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _provider,
      builder: (context, _) {
        final unassignedCount = _provider.project.getUnassignedEvents().length;

        return Scaffold(
          body: Column(
            children: [
              // Global Desktop App Bar
              Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: const BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  border: Border(bottom: BorderSide(color: AppTheme.border)),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minWidth: constraints.maxWidth),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Brand / Logo
                            InkWell(
                              borderRadius: BorderRadius.circular(6),
                              onTap: () => _openProjectSettings(context),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppTheme.goldAccent.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: AppTheme.goldAccent),
                                      ),
                                      child: const Icon(
                                        Icons.movie_outlined,
                                        size: 18,
                                        color: AppTheme.goldAccent,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text(
                                              'BEATWORK',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 1.2,
                                                color: AppTheme.goldAccent,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            ConstrainedBox(
                                              constraints: const BoxConstraints(maxWidth: 160),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 6, vertical: 1.5),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.surfaceLighter,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  _provider.project.title,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppTheme.textPrimary,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          _provider.project.genre,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(width: 12),

                            // View Mode Switcher
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.border),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: AppViewMode.values.map((mode) {
                                  final isSelected = _viewMode == mode;
                                  return InkWell(
                                    borderRadius: BorderRadius.circular(6),
                                    onTap: () => setState(() => _viewMode = mode),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 150),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppTheme.goldAccent
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            mode.icon,
                                            size: 15,
                                            color: isSelected
                                                ? Colors.black
                                                : AppTheme.textSecondary,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            mode.label,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              color: isSelected
                                                  ? Colors.black
                                                  : AppTheme.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),

                            const SizedBox(width: 12),

                            // Quick Actions
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // New Event Button
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.add, size: 15),
                                  label: const Text('New Event'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                  ),
                                  onPressed: () async {
                                    final newEv = await EventDialog.show(context);
                                    if (newEv != null) {
                                      _provider.createEvent(
                                        title: newEv.title,
                                        description: newEv.description,
                                        beatId: newEv.beatId,
                                        emotionalCharge: newEv.emotionalCharge,
                                        characters: newEv.characters,
                                        location: newEv.location,
                                      );
                                    }
                                  },
                                ),
                                const SizedBox(width: 8),

                                // Toggle Event Pool Sidebar
                                Tooltip(
                                  message: 'Toggle Unassigned Event Pool',
                                  child: OutlinedButton.icon(
                                    icon: Icon(
                                      _provider.isEventPoolOpen
                                          ? Icons.view_sidebar
                                          : Icons.view_sidebar_outlined,
                                      size: 16,
                                      color: _provider.isEventPoolOpen
                                          ? AppTheme.goldAccent
                                          : AppTheme.textSecondary,
                                    ),
                                    label: Text(
                                      'Pool ($unassignedCount)',
                                      style: TextStyle(
                                        color: _provider.isEventPoolOpen
                                            ? AppTheme.goldAccent
                                            : AppTheme.textSecondary,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      side: BorderSide(
                                        color: _provider.isEventPoolOpen
                                            ? AppTheme.goldAccent
                                            : AppTheme.border,
                                      ),
                                    ),
                                    onPressed: () => _provider.toggleEventPool(),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Export Button
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.download, size: 15),
                                  label: const Text('Export Script'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                  ),
                                  onPressed: () {
                                    ExportDialog.show(context, provider: _provider);
                                  },
                                ),
                                const SizedBox(width: 8),

                                // Project Menu popup
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, size: 18),
                                  tooltip: 'Project Options',
                                  itemBuilder: (ctx) => [
                                    const PopupMenuItem(
                                      value: 'settings',
                                      child: Row(
                                        children: [
                                          Icon(Icons.settings_outlined, size: 16),
                                          SizedBox(width: 8),
                                          Text('Project Settings'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'sample',
                                      child: Row(
                                        children: [
                                          Icon(Icons.auto_awesome, size: 16, color: AppTheme.goldAccent),
                                          SizedBox(width: 8),
                                          Text('Reload Sample Project (Chronos Cipher)'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'new',
                                      child: Row(
                                        children: [
                                          Icon(Icons.note_add_outlined, size: 16),
                                          SizedBox(width: 8),
                                          Text('Start Fresh Screenplay'),
                                        ],
                                      ),
                                    ),
                                  ],
                                  onSelected: (val) {
                                    if (val == 'settings') {
                                      _openProjectSettings(context);
                                    } else if (val == 'sample') {
                                      _provider.loadSampleProject();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Sample project reloaded.')),
                                      );
                                    } else if (val == 'new') {
                                      _provider.createNewProject();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Created new empty screenplay.')),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Main Workspace Body
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Main View (Beat Sheet Board or Collected Timeline Reader)
                    Expanded(
                      child: _viewMode == AppViewMode.beatSheet
                          ? BeatBoardView(
                              provider: _provider,
                              onOpenBeat: (beat) {
                                BeatDetailDialog.show(
                                  context,
                                  beat: beat,
                                  provider: _provider,
                                );
                              },
                            )
                          : ScriptReaderView(provider: _provider),
                    ),

                    // Collapsible Story Event Pool Sidebar (docked on right)
                    if (_provider.isEventPoolOpen &&
                        _viewMode == AppViewMode.beatSheet)
                      EventPoolSidebar(
                        provider: _provider,
                        onClose: () => _provider.setEventPoolOpen(false),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
