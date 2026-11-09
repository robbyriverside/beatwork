import 'package:flutter/material.dart';

import '../models/slugline.dart';
import '../models/story_project.dart';

class SluglineFields extends StatefulWidget {
  final StoryProject project;
  final String slugline;
  final ValueChanged<String> onChanged;
  final FocusNode locationFocusNode;
  final VoidCallback? onLocationSubmitted;

  const SluglineFields({
    super.key,
    required this.project,
    required this.slugline,
    required this.onChanged,
    required this.locationFocusNode,
    this.onLocationSubmitted,
  });

  @override
  State<SluglineFields> createState() => _SluglineFieldsState();
}

class _SluglineFieldsState extends State<SluglineFields> {
  late final TextEditingController _locationController;
  late String _prefix;
  late String _time;
  late bool _isUnstructured;

  @override
  void initState() {
    super.initState();
    final parsed = Slugline.parse(widget.slugline);
    _isUnstructured = parsed == null && widget.slugline.trim().isNotEmpty;
    _prefix = parsed?.prefix ?? 'INT.';
    _time = parsed?.time ?? 'DAY';
    _locationController = TextEditingController(
      text: parsed?.location ?? widget.slugline,
    );
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  void _updateSlugline() {
    setState(() => _isUnstructured = false);
    widget.onChanged(
      Slugline(
        prefix: _prefix,
        location: _locationController.text,
        time: _time,
      ).format(),
    );
  }

  List<String> _knownLocations() {
    final locations = <String>{};
    for (final event in widget.project.events) {
      final location = event.location.trim().toUpperCase();
      if (location.isNotEmpty) locations.add(location);
    }
    for (final scene in widget.project.scenes) {
      for (final version in scene.versions) {
        final location = Slugline.parse(version.slugline)?.location.trim();
        if (location != null && location.isNotEmpty) {
          locations.add(location.toUpperCase());
        }
      }
    }
    return locations.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    final locations = _knownLocations();
    final times = [...Slugline.times];
    if (!times.contains(_time)) times.add(_time);
    const decoration = InputDecoration(
      isDense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final prefixField = SizedBox(
          width: 110,
          child: DropdownButtonFormField<String>(
            key: const ValueKey('slugline-prefix'),
            initialValue: _prefix,
            isExpanded: true,
            decoration: decoration.copyWith(labelText: 'Prefix'),
            items: Slugline.prefixes
                .map(
                  (prefix) =>
                      DropdownMenuItem(value: prefix, child: Text(prefix)),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              _prefix = value;
              _updateSlugline();
            },
          ),
        );
        final locationField = TextField(
          key: const ValueKey('slugline-location'),
          controller: _locationController,
          focusNode: widget.locationFocusNode,
          textCapitalization: TextCapitalization.characters,
          textInputAction: widget.onLocationSubmitted == null
              ? TextInputAction.next
              : TextInputAction.done,
          onSubmitted: (_) => widget.onLocationSubmitted?.call(),
          onChanged: (_) => _updateSlugline(),
          decoration: decoration.copyWith(
            labelText: 'Location',
            suffixIcon: PopupMenuButton<String>(
              key: const ValueKey('slugline-location-menu'),
              tooltip: 'Choose a known location',
              enabled: locations.isNotEmpty,
              icon: const Icon(Icons.arrow_drop_down),
              onSelected: (location) {
                _locationController.text = location;
                _updateSlugline();
              },
              itemBuilder: (context) => locations
                  .map(
                    (location) => PopupMenuItem(
                      value: location,
                      child: Text(location, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
            ),
          ),
        );
        final timeField = SizedBox(
          width: 150,
          child: DropdownButtonFormField<String>(
            key: const ValueKey('slugline-time'),
            initialValue: _time,
            isExpanded: true,
            decoration: decoration.copyWith(labelText: 'Time'),
            items: times
                .map(
                  (time) => DropdownMenuItem(
                    value: time,
                    child: Text(time, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              _time = value;
              _updateSlugline();
            },
          ),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  prefixField,
                  const SizedBox(width: 8),
                  Expanded(child: locationField),
                  if (constraints.maxWidth >= 450) ...[
                    const SizedBox(width: 8),
                    timeField,
                  ],
                ],
              ),
            ),
            if (constraints.maxWidth < 450) ...[
              const SizedBox(height: 8),
              timeField,
            ],
            if (_isUnstructured)
              const Text(
                'Existing unstructured heading: editing these fields will format it as a slugline.',
              ),
          ],
        );
      },
    );
  }
}
