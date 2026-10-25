import 'package:flutter/material.dart';
import '../models/beat_model.dart';
import '../models/story_event.dart';
import '../theme/app_theme.dart';

class EventDialog extends StatefulWidget {
  final StoryEvent? initialEvent;
  final String? initialBeatId;

  const EventDialog({
    super.key,
    this.initialEvent,
    this.initialBeatId,
  });

  static Future<StoryEvent?> show(
    BuildContext context, {
    StoryEvent? initialEvent,
    String? initialBeatId,
  }) {
    return showDialog<StoryEvent>(
      context: context,
      builder: (context) => EventDialog(
        initialEvent: initialEvent,
        initialBeatId: initialBeatId,
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
  String? _selectedBeatId;

  @override
  void initState() {
    super.initState();
    final ev = widget.initialEvent;
    _titleController = TextEditingController(text: ev?.title ?? '');
    _descController = TextEditingController(text: ev?.description ?? '');
    _charactersController =
        TextEditingController(text: ev?.characters.join(', ') ?? '');
    _locationController = TextEditingController(text: ev?.location ?? '');
    _selectedBeatId = ev?.beatId ?? widget.initialBeatId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _charactersController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialEvent != null;

    return Dialog(
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
                        isEditing ? Icons.edit_note : Icons.add_circle_outline,
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
                    style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Event Title *',
                      hintText: 'e.g. Kael discovers the quantum key in the courier\'s bag',
                      prefixIcon: Icon(Icons.bolt, size: 18, color: AppTheme.goldAccent),
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
                    controller: _descController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Detailed Narrative Description',
                      hintText: 'What happens? What are the stakes, obstacles, or emotional undercurrents?',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Assigned Beat Dropdown
                  DropdownButtonFormField<String?>(
                    initialValue: _selectedBeatId,
                    decoration: const InputDecoration(
                      labelText: 'Assign to Beat',
                      prefixIcon: Icon(Icons.dashboard_customize_outlined, size: 18),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check, size: 18),
                        label: Text(isEditing ? 'Save Changes' : 'Create Event'),
                        onPressed: () {
                          if (!_formKey.currentState!.validate()) return;

                          final chars = _charactersController.text
                              .split(',')
                              .map((c) => c.trim())
                              .where((c) => c.isNotEmpty)
                              .toList();

                          final result = (widget.initialEvent ??
                                  StoryEvent(
                                    id: '',
                                    title: '',
                                  ))
                              .copyWith(
                            title: _titleController.text.trim(),
                            description: _descController.text.trim(),
                            beatId: _selectedBeatId,
                            clearBeatId: _selectedBeatId == null,
                            characters: chars,
                            location: _locationController.text.trim(),
                          );

                          Navigator.of(context).pop(result);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
