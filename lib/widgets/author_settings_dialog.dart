import 'package:flutter/material.dart';

import '../models/author_profile.dart';
import '../state/story_provider.dart';
import '../theme/app_theme.dart';

class AuthorSettingsDialog extends StatefulWidget {
  final StoryProvider provider;

  const AuthorSettingsDialog({super.key, required this.provider});

  @override
  State<AuthorSettingsDialog> createState() => _AuthorSettingsDialogState();
}

class _AuthorSettingsDialogState extends State<AuthorSettingsDialog> {
  late final TextEditingController _name;
  late final TextEditingController _email;
  bool _saving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.provider.author.name);
    _email = TextEditingController(text: widget.provider.author.email);
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      await widget.provider.updateAuthor(
        AuthorProfile(name: _name.text.trim(), email: _email.text.trim()),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _saveError = 'Could not save Author settings: $error';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
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
            controller: _name,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Author name'),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('author-email-field'),
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          if (_saveError != null) ...[
            const SizedBox(height: 12),
            Text(_saveError!, style: const TextStyle(color: Colors.red)),
          ],
        ],
      ),
    ),
    actions: [
      OutlinedButton(
        onPressed: _saving ? null : () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      ElevatedButton(
        onPressed: _saving ? null : _save,
        child: const Text('Save'),
      ),
    ],
  );
}
