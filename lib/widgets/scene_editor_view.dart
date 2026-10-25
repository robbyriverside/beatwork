import 'package:flutter/material.dart';
import '../models/beat_model.dart';
import '../models/scene_model.dart';
import '../state/story_provider.dart';
import '../theme/app_theme.dart';

class SceneEditorView extends StatefulWidget {
  final Scene scene;
  final BeatDefinition beat;
  final StoryProvider provider;

  const SceneEditorView({
    super.key,
    required this.scene,
    required this.beat,
    required this.provider,
  });

  @override
  State<SceneEditorView> createState() => _SceneEditorViewState();
}

class _SceneEditorViewState extends State<SceneEditorView> {
  late TextEditingController _titleController;
  late TextEditingController _sluglineController;
  late TextEditingController _scriptController;
  late TextEditingController _summaryController;
  late TextEditingController _notesController;

  bool _isReferenceMode = false;
  String? _referenceVersionId;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    final active = widget.scene.activeVersion;
    _titleController = TextEditingController(text: widget.scene.title);
    _sluglineController = TextEditingController(text: active.slugline);
    _scriptController = TextEditingController(text: active.scriptContent);
    _summaryController = TextEditingController(text: active.summary);
    _notesController = TextEditingController(text: active.notes);

    // Default reference version to first version if multiple exist
    if (widget.scene.versions.length > 1) {
      _referenceVersionId = widget.scene.versions.first.id;
    }
  }

  @override
  void didUpdateWidget(covariant SceneEditorView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scene.id != widget.scene.id ||
        oldWidget.scene.activeVersionId != widget.scene.activeVersionId) {
      final active = widget.scene.activeVersion;
      _titleController.text = widget.scene.title;
      _sluglineController.text = active.slugline;
      _scriptController.text = active.scriptContent;
      _summaryController.text = active.summary;
      _notesController.text = active.notes;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _sluglineController.dispose();
    _scriptController.dispose();
    _summaryController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _saveCurrentVersion() {
    widget.provider.updateActiveVersionContent(
      widget.scene.id,
      slugline: _sluglineController.text.trim(),
      summary: _summaryController.text.trim(),
      scriptContent: _scriptController.text,
      notes: _notesController.text.trim(),
    );
  }

  void _insertFormattingSnippet(String prefix, String suffix) {
    final text = _scriptController.text;
    final selection = _scriptController.selection;
    final selectedText = selection.isCollapsed
        ? ''
        : text.substring(selection.start, selection.end);
    final replacement = '$prefix$selectedText$suffix';

    final newText = text.replaceRange(
      selection.isValid ? selection.start : text.length,
      selection.isValid ? selection.end : text.length,
      replacement,
    );

    _scriptController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset:
            (selection.isValid ? selection.start : text.length) +
            replacement.length,
      ),
    );
    _saveCurrentVersion();
  }

  @override
  Widget build(BuildContext context) {
    final activeVersion = widget.scene.activeVersion;
    final beatEvents = widget.provider.project.getEventsForBeat(widget.beat.id);

    SceneVersion? refVersion;
    if (_isReferenceMode && _referenceVersionId != null) {
      try {
        refVersion = widget.scene.versions.firstWhere(
          (v) => v.id == _referenceVersionId,
        );
      } catch (_) {
        refVersion = null;
      }
    }

    return Container(
      color: AppTheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Scene Title, Slugline & Top Controls
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceElevated,
              border: Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _titleController,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Scene Title',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        onChanged: (val) {
                          widget.scene.title = val;
                          widget.provider.updateScene(widget.scene);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _sluglineController,
                        style: AppTheme.screenplaySlugline,
                        decoration: const InputDecoration(
                          labelText: 'Scene Heading / Slugline',
                          hintText: 'e.g. INT. COFFEE SHOP - DAY',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        onChanged: (_) => _saveCurrentVersion(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Reference mode toggle
                    OutlinedButton.icon(
                      icon: Icon(
                        _isReferenceMode ? Icons.splitscreen : Icons.history,
                        size: 16,
                        color: _isReferenceMode
                            ? AppTheme.goldAccent
                            : AppTheme.textSecondary,
                      ),
                      label: Text(
                        _isReferenceMode ? 'Hide Reference' : 'Reference Mode',
                        style: TextStyle(
                          color: _isReferenceMode
                              ? AppTheme.goldAccent
                              : AppTheme.textSecondary,
                        ),
                      ),
                      onPressed: () {
                        setState(() => _isReferenceMode = !_isReferenceMode);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Mapped Beat Events Selector
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Mapped Beat Events: ',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (beatEvents.isEmpty)
                      const Text(
                        'No events in this beat yet. Add events to map this scene.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppTheme.textMuted,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    else
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: beatEvents.map((ev) {
                              final isMapped = widget.scene.mappedEventIds
                                  .contains(ev.id);
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: FilterChip(
                                  selected: isMapped,
                                  label: Text(ev.title),
                                  selectedColor: AppTheme.goldAccent,
                                  backgroundColor: AppTheme.surface,
                                  labelStyle: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isMapped
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isMapped
                                        ? Colors.black
                                        : AppTheme.textPrimary,
                                  ),
                                  padding: EdgeInsets.zero,
                                  onSelected: (_) {
                                    widget.provider.toggleEventMappingForScene(
                                      widget.scene.id,
                                      ev.id,
                                    );
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Versions Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              border: Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.source_outlined,
                  size: 16,
                  color: AppTheme.goldAccent,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Versions:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: widget.scene.versions.map((ver) {
                        final isActive = ver.id == widget.scene.activeVersionId;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            selected: isActive,
                            label: Text(
                              'v${ver.versionNumber}: ${ver.label.isNotEmpty ? ver.label : "Draft"}',
                            ),
                            selectedColor: AppTheme.goldAccent.withOpacity(
                              0.25,
                            ),
                            backgroundColor: AppTheme.surfaceElevated,
                            labelStyle: TextStyle(
                              fontSize: 11,
                              fontWeight: isActive
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isActive
                                  ? AppTheme.goldAccent
                                  : AppTheme.textSecondary,
                            ),
                            padding: EdgeInsets.zero,
                            onSelected: (selected) {
                              if (selected) {
                                widget.provider.setActiveSceneVersion(
                                  widget.scene.id,
                                  ver.id,
                                );
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                // "+ New Version" button
                ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('New Version'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    textStyle: const TextStyle(fontSize: 11.5),
                  ),
                  onPressed: () => _promptNewVersion(context),
                ),
              ],
            ),
          ),

          // Main Screenplay Workspace: single or side-by-side reference view
          Expanded(
            child: _isReferenceMode
                ? Row(
                    children: [
                      // Reference Panel (Left)
                      Expanded(
                        child: Container(
                          decoration: const BoxDecoration(
                            border: Border(
                              right: BorderSide(color: AppTheme.border),
                            ),
                            color: AppTheme.surface,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                color: AppTheme.surfaceElevated,
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.history_edu,
                                      size: 16,
                                      color: AppTheme.cyanAccent,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'REFERENCE VERSION',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.8,
                                        color: AppTheme.cyanAccent,
                                      ),
                                    ),
                                    const Spacer(),
                                    DropdownButton<String>(
                                      value: _referenceVersionId,
                                      isDense: true,
                                      dropdownColor: AppTheme.surfaceElevated,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: AppTheme.textPrimary,
                                      ),
                                      items: widget.scene.versions.map((v) {
                                        return DropdownMenuItem<String>(
                                          value: v.id,
                                          child: Text(
                                            'v${v.versionNumber}: ${v.label}',
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        setState(
                                          () => _referenceVersionId = val,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.all(16),
                                  child: refVersion == null
                                      ? const Center(
                                          child: Text(
                                            'No reference version chosen',
                                          ),
                                        )
                                      : Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              refVersion.slugline.toUpperCase(),
                                              style: AppTheme.screenplaySlugline
                                                  .copyWith(
                                                    color: AppTheme.cyanAccent,
                                                  ),
                                            ),
                                            const SizedBox(height: 12),
                                            if (refVersion
                                                .summary
                                                .isNotEmpty) ...[
                                              Text(
                                                'Summary: ${refVersion.summary}',
                                                style: const TextStyle(
                                                  fontStyle: FontStyle.italic,
                                                  fontSize: 12,
                                                  color: AppTheme.textMuted,
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                            ],
                                            SelectableText(
                                              refVersion.scriptContent.isEmpty
                                                  ? '(Empty draft)'
                                                  : refVersion.scriptContent,
                                              style: AppTheme.screenplayAction,
                                            ),
                                            if (refVersion
                                                .notes
                                                .isNotEmpty) ...[
                                              const SizedBox(height: 16),
                                              const Divider(
                                                color: AppTheme.border,
                                              ),
                                              Text(
                                                'Notes: ${refVersion.notes}',
                                                style: const TextStyle(
                                                  fontSize: 11.5,
                                                  color: AppTheme.textMuted,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Active Version Editor (Right)
                      Expanded(child: _buildActiveEditor(activeVersion)),
                    ],
                  )
                : _buildActiveEditor(activeVersion),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveEditor(SceneVersion activeVersion) {
    return Column(
      children: [
        // Helper Toolbar for Screenplay formatting
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: const BoxDecoration(
            color: AppTheme.surfaceElevated,
            border: Border(bottom: BorderSide(color: AppTheme.border)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text(
                  'Format Snippets:',
                  style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
                const SizedBox(width: 8),
                _formatSnippetButton('Action', '\n', '\n'),
                _formatSnippetButton('CHARACTER', '\n\n', '\n'),
                _formatSnippetButton('(Parenthetical)', '(', ')'),
                _formatSnippetButton('TRANSITION:', '\n\n', ' TO:\n\n'),
              ],
            ),
          ),
        ),

        // Editor Body
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: TextField(
                    controller: _scriptController,
                    maxLines: null,
                    expands: true,
                    style: AppTheme.screenplayAction,
                    decoration: const InputDecoration(
                      hintText:
                          'Write your scene in screenplay format...\n\nKAEL\nI knew you were listening.\n\nHe leans against the console, fingers hovering over the red wire.',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      fillColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                    ),
                    onChanged: (_) => _saveCurrentVersion(),
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(color: AppTheme.border, height: 1),
                const SizedBox(height: 8),

                // Scene Notes & Summary expandable bottom
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _summaryController,
                        decoration: const InputDecoration(
                          labelText: 'Scene Objective / Summary',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                        ),
                        onChanged: (_) => _saveCurrentVersion(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Writer Notes & Revision Thoughts',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                        ),
                        onChanged: (_) => _saveCurrentVersion(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _formatSnippetButton(String label, String prefix, String suffix) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: () => _insertFormattingSnippet(prefix, suffix),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppTheme.border),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontFamily: 'Courier',
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  void _promptNewVersion(BuildContext context) {
    final labelCtrl = TextEditingController(
      text: 'Draft ${widget.scene.versions.length + 1}',
    );
    final notesCtrl = TextEditingController(
      text: 'Branched from v${widget.scene.activeVersion.versionNumber}',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.difference_outlined, color: AppTheme.goldAccent),
            SizedBox(width: 8),
            Text('Create New Scene Version'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'A new version will be created, retaining the current script text so you can refine or explore an alternate direction while keeping past drafts as a reference.',
              style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: labelCtrl,
              decoration: const InputDecoration(
                labelText: 'Version Label / Focus',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Revision Intent / Notes',
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
              widget.provider.createNextSceneVersion(
                widget.scene.id,
                label: labelCtrl.text.trim(),
                notes: notesCtrl.text.trim(),
              );
              Navigator.of(ctx).pop();
            },
            child: const Text('Create Version'),
          ),
        ],
      ),
    );
  }
}
