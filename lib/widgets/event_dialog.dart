import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/beat_model.dart';
import '../models/story_event.dart';
import '../theme/app_theme.dart';

class EventDialog extends StatefulWidget {
  final StoryEvent? initialEvent;
  final String? initialBeatId;
  final void Function(StoryEvent event, bool isEditing)? onSaveAndContinue;

  const EventDialog({
    super.key,
    this.initialEvent,
    this.initialBeatId,
    this.onSaveAndContinue,
  });

  static Future<StoryEvent?> show(
    BuildContext context, {
    StoryEvent? initialEvent,
    String? initialBeatId,
    void Function(StoryEvent event, bool isEditing)? onSaveAndContinue,
  }) {
    return showDialog<StoryEvent>(
      context: context,
      builder: (context) => EventDialog(
        initialEvent: initialEvent,
        initialBeatId: initialBeatId,
        onSaveAndContinue: onSaveAndContinue,
      ),
    );
  }

  @override
  State<EventDialog> createState() => _EventDialogState();
}

class _EventDialogState extends State<EventDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _charactersController;
  late TextEditingController _locationController;
  late FocusNode _titleFocusNode;
  late FocusNode _descriptionFocusNode;
  late bool _isEditing;
  String? _selectedBeatId;

  @override
  void initState() {
    super.initState();
    final ev = widget.initialEvent;
    _titleController = TextEditingController(text: ev?.title ?? '');
    _descController = TextEditingController(text: ev?.description ?? '');
    _charactersController = TextEditingController(
      text: ev?.characters.join(', ') ?? '',
    );
    _locationController = TextEditingController(text: ev?.location ?? '');
    _titleFocusNode = FocusNode();
    _descriptionFocusNode = FocusNode();
    _isEditing = ev != null;
    _selectedBeatId = ev?.beatId ?? widget.initialBeatId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _charactersController.dispose();
    _locationController.dispose();
    _titleFocusNode.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  void _cancel() => Navigator.of(context).pop();

  StoryEvent _currentEvent() {
    final chars = _charactersController.text
        .split(',')
        .map((character) => character.trim())
        .where((character) => character.isNotEmpty)
        .toList();

    return (_isEditing ? widget.initialEvent! : StoryEvent(id: '', title: ''))
        .copyWith(
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          beatId: _selectedBeatId,
          clearBeatId: _selectedBeatId == null,
          characters: chars,
          location: _locationController.text.trim(),
        );
  }

  bool _validate() => _formKey.currentState!.validate();

  void _saveEvent() {
    if (!_validate()) return;
    Navigator.of(context).pop(_currentEvent());
  }

  void _saveAndStartAnother() {
    if (!_validate()) return;
    final saveAndContinue = widget.onSaveAndContinue;
    if (saveAndContinue == null) {
      _saveEvent();
      return;
    }

    saveAndContinue(_currentEvent(), _isEditing);
    setState(() {
      _formKey.currentState!.reset();
      _isEditing = false;
      _titleController.clear();
      _descController.clear();
      _charactersController.clear();
      _titleController.selection = const TextSelection.collapsed(offset: 0);
    });
    _titleFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = _isEditing;

    return CallbackShortcuts(
      bindings: {
        SingleActivator(
          LogicalKeyboardKey.enter,
          meta: Platform.isMacOS,
          control: !Platform.isMacOS,
        ): _saveEvent,
        SingleActivator(
          LogicalKeyboardKey.keyE,
          meta: Platform.isMacOS,
          control: !Platform.isMacOS,
        ): _saveAndStartAnother,
        const SingleActivator(LogicalKeyboardKey.escape): _cancel,
      },
      child: Dialog(
        backgroundColor: AppTheme.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppTheme.borderHighlight),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isEditing
                              ? Icons.edit_note
                              : Icons.add_circle_outline,
                          color: AppTheme.goldAccent,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          isEditing ? 'Edit Story Event' : 'Create Story Event',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Events represent things that happen in the story. You can create them freely and drag them into Save the Cat beats.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title
                    TextFormField(
                      key: const ValueKey('event-title-field'),
                      controller: _titleController,
                      focusNode: _titleFocusNode,
                      autofocus: true,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) =>
                          _descriptionFocusNode.requestFocus(),
                      decoration: const InputDecoration(
                        labelText: 'Event Title *',
                        hintText:
                            'e.g. Kael discovers the quantum key in the courier\'s bag',
                        prefixIcon: Icon(
                          Icons.bolt,
                          size: 18,
                          color: AppTheme.goldAccent,
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Event title is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Description
                    TextFormField(
                      key: const ValueKey('event-description-field'),
                      controller: _descController,
                      focusNode: _descriptionFocusNode,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Detailed Narrative Description',
                        hintText:
                            'What happens? What are the stakes, obstacles, or emotional undercurrents?',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Assigned Beat Dropdown
                    DropdownButtonFormField<String?>(
                      key: const ValueKey('event-beat-field'),
                      initialValue: _selectedBeatId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Assign to Beat',
                        prefixIcon: Icon(
                          Icons.dashboard_customize_outlined,
                          size: 18,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Story Event Pool (Unassigned inbox)'),
                        ),
                        ...BeatDefinition.saveTheCatBeats.map(
                          (b) => DropdownMenuItem<String?>(
                            value: b.id,
                            child: Text(
                              'Beat ${b.number}: ${b.name} (${b.act.title})',
                              style: const TextStyle(fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() => _selectedBeatId = val);
                      },
                    ),
                    const SizedBox(height: 14),

                    // Characters & Location
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _charactersController,
                            decoration: const InputDecoration(
                              labelText: 'Characters Involved',
                              hintText: 'e.g. Kael, Elena, Jax',
                              prefixIcon: Icon(Icons.people_outline, size: 18),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            key: const ValueKey('event-location-field'),
                            controller: _locationController,
                            decoration: const InputDecoration(
                              labelText: 'Location / Setting',
                              hintText: 'e.g. Skyline Antenna',
                              prefixIcon: Icon(Icons.place_outlined, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Actions
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed: _cancel,
                          child: const Text('Cancel'),
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Save & New  (%E)'),
                          onPressed: _saveAndStartAnother,
                        ),
                        ElevatedButton(
                          child: Text(
                            isEditing
                                ? 'Save Changes  (%Enter)'
                                : 'Create Event  (%Enter)',
                          ),
                          onPressed: _saveEvent,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
