import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/beat_sheet.dart';
import '../models/story_project.dart';

class NewProjectDialog extends StatefulWidget {
  final List<({String yaml, BeatSheet sheet})> sheets;

  const NewProjectDialog({super.key, required this.sheets});

  static Future<List<({String yaml, BeatSheet sheet})>> loadSheets() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final paths =
        manifest
            .listAssets()
            .where(
              (path) =>
                  path.startsWith('assets/beat_sheets/') &&
                  path.endsWith('.yaml'),
            )
            .toList()
          ..sort();
    if (paths.isEmpty) throw const FormatException('No beat sheets found.');
    final sheets = <({String yaml, BeatSheet sheet})>[];
    final ids = <String>{};
    for (final path in paths) {
      final yaml = await rootBundle.loadString(path);
      final sheet = BeatSheet.fromYaml(yaml, 110);
      if (!ids.add(sheet.id)) {
        throw FormatException('Duplicate beat sheet id: ${sheet.id}');
      }
      sheets.add((yaml: yaml, sheet: sheet));
    }
    return sheets;
  }

  @override
  State<NewProjectDialog> createState() => _NewProjectDialogState();
}

class _NewProjectDialogState extends State<NewProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _pages = TextEditingController(text: '110');
  final _title = TextEditingController();
  final _titleFocus = FocusNode();
  final _logline = TextEditingController();
  final _loglineFocus = FocusNode();
  final _genre = TextEditingController(text: 'Feature Film');
  late String _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.sheets.any((entry) => entry.sheet.id == 'save_the_cat')
        ? 'save_the_cat'
        : widget.sheets.first.sheet.id;
  }

  @override
  void dispose() {
    _pages.dispose();
    _title.dispose();
    _titleFocus.dispose();
    _logline.dispose();
    _loglineFocus.dispose();
    _genre.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Project'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  key: const ValueKey('new-project-title'),
                  controller: _title,
                  focusNode: _titleFocus,
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => _loglineFocus.requestFocus(),
                  decoration: const InputDecoration(
                    labelText: 'Screenplay Title (required)',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a screenplay title.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey('new-project-logline'),
                  controller: _logline,
                  focusNode: _loglineFocus,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Logline / Premise',
                    hintText:
                        'A one-sentence summary with protagonist, conflict, and stakes.',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey('new-project-genre'),
                  controller: _genre,
                  decoration: const InputDecoration(
                    labelText: 'Genre / Format',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  key: const ValueKey('new-project-beat-sheet'),
                  initialValue: _selectedId,
                  decoration: const InputDecoration(labelText: 'Beat sheet'),
                  items: widget.sheets
                      .map(
                        (entry) => DropdownMenuItem(
                          value: entry.sheet.id,
                          child: Text(entry.sheet.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _selectedId = value!),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const ValueKey('new-project-page-count'),
                  controller: _pages,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Target pages / minutes',
                    helperText: 'Used to estimate beats, not a writing limit.',
                  ),
                  validator: (value) {
                    final pages = int.tryParse(value ?? '');
                    return pages == null || pages < 1 || pages > 1000
                        ? 'Enter a whole number from 1 to 1000.'
                        : null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (!_formKey.currentState!.validate()) {
              if (_title.text.trim().isEmpty) {
                _titleFocus.requestFocus();
                await SystemSound.play(SystemSoundType.alert);
              }
              return;
            }
            final pages = int.parse(_pages.text);
            final yaml = widget.sheets
                .firstWhere((entry) => entry.sheet.id == _selectedId)
                .yaml;
            final project = StoryProject.createEmptyProject(
              title: _title.text.trim(),
              logline: _logline.text.trim(),
              genre: _genre.text.trim(),
              beatSheetYaml: yaml,
              targetPageCount: pages,
            );
            Navigator.pop(context, project);
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}
