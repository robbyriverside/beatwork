import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io';
import 'models/story_project.dart';
import 'services/storage_service.dart';
import 'state/story_provider.dart';
import 'theme/app_theme.dart';
import 'widgets/beat_board_view.dart';
import 'widgets/beat_detail_dialog.dart';
import 'widgets/event_dialog.dart';
import 'widgets/event_pool_sidebar.dart';
import 'widgets/script_reader_view.dart';

const _documentChannel = MethodChannel('beatwork/documents');

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  StoryProject? savedProject;
  String? documentPath;
  final launchPath = args.cast<String?>().firstWhere(
    (path) => path != null && path.toLowerCase().endsWith('.beats'),
    orElse: () => null,
  );
  try {
    if (launchPath != null) {
      savedProject = await StorageService.openDocument(launchPath);
      documentPath = launchPath;
    } else {
      final recent = await StorageService.listRecentDocuments();
      if (recent.isNotEmpty) {
        savedProject = await StorageService.openDocument(recent.first.path);
        documentPath = recent.first.path;
      }
    }
  } catch (error) {
    debugPrint('Could not open launch document: $error');
  }

  runApp(
    BeatWorkApp(
      initialProject: savedProject ?? StoryProject.createSampleProject(),
      initialDocumentPath: documentPath,
    ),
  );
}

class BeatWorkApp extends StatelessWidget {
  final StoryProject? initialProject;
  final String? initialDocumentPath;

  const BeatWorkApp({super.key, this.initialProject, this.initialDocumentPath});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BeatWork - Save the Cat Screenplay Beats',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: BeatWorkHomeScreen(
        initialProject: initialProject,
        initialDocumentPath: initialDocumentPath,
      ),
    );
  }
}

enum AppViewMode {
  beatSheet('Beat Sheet Board', Icons.dashboard_outlined),
  timelineReader('Script Timeline', Icons.auto_stories_outlined);

  final String label;
  final IconData icon;
  const AppViewMode(this.label, this.icon);
}

class BeatWorkHomeScreen extends StatefulWidget {
  final StoryProject? initialProject;
  final String? initialDocumentPath;

  const BeatWorkHomeScreen({
    super.key,
    this.initialProject,
    this.initialDocumentPath,
  });

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
      initialProject:
          widget.initialProject ?? StoryProject.createSampleProject(),
      documentPath: widget.initialDocumentPath,
    );
    _documentChannel.setMethodCallHandler(_handlePlatformMethodCall);
    if (Platform.isMacOS) {
      _documentChannel.invokeMethod<void>('ready').catchError((_) {});
    }
  }

  Future<Object?> _handlePlatformMethodCall(MethodCall call) async {
    if (call.method == 'openDocument' && call.arguments is String) {
      await _openRecentDocument(call.arguments as String);
      return null;
    } else if (call.method == 'showEventPool') {
      _provider.setEventPoolOpen(true);
      if (_viewMode != AppViewMode.beatSheet) {
        setState(() => _viewMode = AppViewMode.beatSheet);
      }
      return null;
    } else if (call.method == 'requestExit') {
      return await _confirmExit();
    }
    return null;
  }

  @override
  void dispose() {
    _documentChannel.setMethodCallHandler(null);
    _provider.dispose();
    super.dispose();
  }

  Future<bool> _confirmDocumentReplacement() async {
    if (!_provider.hasUnsavedChanges) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Unsaved Project'),
        content: const Text('Save your changes before replacing this project?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Discard'),
          ),
          ElevatedButton(
            onPressed: () async {
              final saved = _provider.documentPath == null
                  ? await _provider.saveDocumentAs()
                  : await _provider.saveDocument();
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext, saved);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<bool> _confirmExit() async {
    if (!_provider.hasUnsavedChanges) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Save before quitting?'),
        content: const Text('Your project has unsaved changes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Discard'),
          ),
          ElevatedButton(
            onPressed: () async {
              final saved = _provider.documentPath == null
                  ? await _provider.saveDocumentAs()
                  : await _provider.saveDocument();
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext, saved);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _newDocument() async {
    if (await _confirmDocumentReplacement()) _provider.newDocument();
  }

  Future<void> _openDocument() async {
    final path = await StorageService.pickDocumentPath();
    if (path == null) return;
    if (!await _confirmDocumentReplacement()) return;
    if (!await _provider.openDocument(path) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the selected project.')),
      );
    }
  }

  Future<void> _openRecentDocument(String path) async {
    if (!await _confirmDocumentReplacement()) return;
    if (!await _provider.openDocument(path) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the recent project.')),
      );
    }
  }

  Future<void> _saveDocument({bool saveAs = false}) async {
    if (!saveAs &&
        _provider.documentPath != null &&
        !_provider.hasUnsavedChanges) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Project up to date')));
      }
      return;
    }

    final saved = saveAs || _provider.documentPath == null
        ? await _provider.saveDocumentAs(
            initialDirectory: _provider.documentPath == null
                ? null
                : File(_provider.documentPath!).parent.path,
          )
        : await _provider.saveDocument();
    if (!saved && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Project was not saved.')));
    }
  }

  void _openProjectSettings(BuildContext context) {
    final titleCtrl = TextEditingController(text: _provider.project.title);
    final loglineCtrl = TextEditingController(text: _provider.project.logline);
    final genreCtrl = TextEditingController(text: _provider.project.genre);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.movie_filter_outlined, color: AppTheme.goldAccent),
            SizedBox(width: 8),
            Text('Project'),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Screenplay Title',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: loglineCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Logline / Premise',
                  hintText:
                      'A one-sentence summary with protagonist, conflict, and stakes.',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: genreCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Genre / Format',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
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
              );
              Navigator.of(ctx).pop();
            },
            child: const Text('Save Details'),
          ),
        ],
      ),
    );
  }

  void _openAuthorSettings(BuildContext context) {
    final authorCtrl = TextEditingController(text: _provider.project.author);
    final emailCtrl = TextEditingController(
      text: _provider.project.authorEmail,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.person_outline, color: AppTheme.goldAccent),
            SizedBox(width: 8),
            Text('Author'),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                key: const ValueKey('author-name-field'),
                controller: authorCtrl,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Author name'),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('author-email-field'),
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
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
                author: authorCtrl.text.trim(),
                authorEmail: emailCtrl.text.trim(),
              );
              Navigator.of(ctx).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAbout(BuildContext context) async {
    var appVersion = '1.0.0';
    try {
      appVersion = (await PackageInfo.fromPlatform()).version;
    } on MissingPluginException {
      // The app may be running before native plugin registration is refreshed.
    }
    if (!mounted) return;

    showAboutDialog(
      context: context,
      applicationName: 'BeatWork',
      applicationVersion: appVersion,
      applicationLegalese: 'Save the Cat! Screenwriting Workflow',
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _provider,
      builder: (context, _) {
        final unassignedCount = _provider.project.getUnassignedEvents().length;
        final usesMetaModifier = Platform.isMacOS;
        SingleActivator menuShortcut(
          LogicalKeyboardKey key, {
          bool shift = false,
        }) => SingleActivator(
          key,
          meta: usesMetaModifier,
          control: !usesMetaModifier,
          shift: shift,
        );
        final newShortcut = menuShortcut(LogicalKeyboardKey.keyN);
        final openShortcut = menuShortcut(LogicalKeyboardKey.keyO);
        final saveShortcut = menuShortcut(LogicalKeyboardKey.keyS);
        final saveAsShortcut = menuShortcut(
          LogicalKeyboardKey.keyS,
          shift: true,
        );
        final infoShortcut = menuShortcut(LogicalKeyboardKey.keyI);

        return CallbackShortcuts(
          bindings: {
            newShortcut: _newDocument,
            openShortcut: _openDocument,
            saveShortcut: () => _saveDocument(),
            saveAsShortcut: () => _saveDocument(saveAs: true),
            infoShortcut: () => _openProjectSettings(context),
          },
          child: Focus(
            autofocus: true,
            child: Scaffold(
              body: Column(
                children: [
                  // Global Desktop App Bar
                  Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: const BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      border: Border(
                        bottom: BorderSide(color: AppTheme.border),
                      ),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: constraints.maxWidth,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Brand / Logo
                                MenuAnchor(
                                  menuChildren: [
                                    MenuItemButton(
                                      onPressed: _newDocument,
                                      shortcut: newShortcut,
                                      child: const Text('New'),
                                    ),
                                    MenuItemButton(
                                      onPressed: _openDocument,
                                      shortcut: openShortcut,
                                      child: const Text('Open...'),
                                    ),
                                    MenuItemButton(
                                      onPressed: () => _saveDocument(),
                                      shortcut: saveShortcut,
                                      child: const Text('Save'),
                                    ),
                                    MenuItemButton(
                                      onPressed: () =>
                                          _saveDocument(saveAs: true),
                                      shortcut: saveAsShortcut,
                                      child: const Text('Save As...'),
                                    ),
                                    SubmenuButton(
                                      menuChildren:
                                          _provider.recentDocuments.isEmpty
                                          ? [
                                              const MenuItemButton(
                                                onPressed: null,
                                                child: Text(
                                                  'No Recent Projects',
                                                ),
                                              ),
                                            ]
                                          : _provider.recentDocuments
                                                .map(
                                                  (document) => MenuItemButton(
                                                    onPressed: () =>
                                                        _openRecentDocument(
                                                          document.path,
                                                        ),
                                                    child: Text(document.title),
                                                  ),
                                                )
                                                .toList(),
                                      child: const Text('Open Recent'),
                                    ),
                                  ],
                                  builder: (context, controller, child) =>
                                      SizedBox(
                                        height: 56,
                                        child: Center(
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            onTap: () => controller.isOpen
                                                ? controller.close()
                                                : controller.open(),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 6,
                                                  ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(6),
                                                    decoration: BoxDecoration(
                                                      color: AppTheme.goldAccent
                                                          .withValues(
                                                            alpha: 0.2,
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            6,
                                                          ),
                                                      border: Border.all(
                                                        color:
                                                            AppTheme.goldAccent,
                                                      ),
                                                    ),
                                                    child: const Icon(
                                                      Icons.movie_outlined,
                                                      size: 18,
                                                      color:
                                                          AppTheme.goldAccent,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  const Text(
                                                    'BEATWORK',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      letterSpacing: 1.2,
                                                      color:
                                                          AppTheme.goldAccent,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                ),

                                const SizedBox(width: 16),

                                InkWell(
                                  key: const ValueKey('project-title-action'),
                                  borderRadius: BorderRadius.circular(4),
                                  onTap: () => _openProjectSettings(context),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 4,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 160,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 1.5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppTheme.surfaceElevated,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              _provider.project.title,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme.textPrimary,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 160,
                                          child: Text(
                                            _provider.project.logline,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: AppTheme.textSecondary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
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
                                        onTap: () =>
                                            setState(() => _viewMode = mode),
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 150,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? AppTheme.goldAccent
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
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
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          side: BorderSide(
                                            color: _provider.isEventPoolOpen
                                                ? AppTheme.goldAccent
                                                : AppTheme.border,
                                          ),
                                        ),
                                        onPressed: () =>
                                            _provider.toggleEventPool(),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    PopupMenuButton<String>(
                                      tooltip: 'Settings',
                                      icon: const Icon(Icons.settings_outlined),
                                      onSelected: (item) {
                                        switch (item) {
                                          case 'system':
                                            _openProjectSettings(context);
                                          case 'author':
                                            _openAuthorSettings(context);
                                          case 'about':
                                            _showAbout(context);
                                        }
                                      },
                                      itemBuilder: (context) => const [
                                        PopupMenuItem(
                                          value: 'system',
                                          child: Text('Project'),
                                        ),
                                        PopupMenuItem(
                                          value: 'author',
                                          child: Text('Author'),
                                        ),
                                        PopupMenuDivider(),
                                        PopupMenuItem(
                                          value: 'about',
                                          child: Text('About'),
                                        ),
                                      ],
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
                                  onOpenEvent: (event) async {
                                    final updated = await EventDialog.show(
                                      context,
                                      initialEvent: event,
                                    );
                                    if (updated != null) {
                                      _provider.updateEvent(updated);
                                    }
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
            ),
          ),
        );
      },
    );
  }
}
