import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:yaml/yaml.dart';

import 'beat_model.dart';

class BeatSheet {
  final String id;
  final String name;
  final String timelineLabel;
  final List<StoryAct> acts;
  final List<BeatDefinition> beats;

  BeatSheet({
    required this.id,
    required this.name,
    required this.timelineLabel,
    required this.acts,
    required this.beats,
  });

  static final legacy = BeatSheet(
    id: 'save_the_cat',
    name: 'Save the Cat!',
    timelineLabel: 'SAVE THE CAT',
    acts: StoryAct.values,
    beats: BeatDefinition.saveTheCatBeats,
  );

  /// Materialize estimated templates so future changes cannot alter a project.
  String toFixedYaml() {
    String color(Color value) =>
        (value.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0');
    return jsonEncode({
      'version': 1,
      'id': id,
      'name': name,
      'timeline_label': timelineLabel,
      'mode': 'fixed',
      'acts': [
        for (var i = 0; i < acts.length; i++)
          {
            'id': 'act_${i + 1}',
            'title': acts[i].title,
            'subtitle': acts[i].subtitle,
            'color': color(acts[i].accentColor),
            'dark_color': color(acts[i].darkBg),
            'beats': [
              for (final beat in beats.where((beat) => beat.act == acts[i]))
                {
                  'id': beat.id,
                  'name': beat.name,
                  'target_page': beat.targetPage,
                  'percentage': beat.percentage,
                  'summary': beat.shortSummary,
                  'guidance': beat.guidance,
                  'icon': _icons.entries
                      .firstWhere((entry) => entry.value == beat.icon)
                      .key,
                },
            ],
          },
      ],
    });
  }

  factory BeatSheet.fromYaml(String source, int pages) {
    if (pages < 1 || pages > 1000) {
      throw const FormatException('Page count must be between 1 and 1000.');
    }
    final root = _map(loadYaml(source), 'beat sheet');
    if (root['version'] != 1) {
      throw const FormatException('Unsupported beat sheet version.');
    }
    final id = _string(root, 'id');
    final name = _string(root, 'name');
    final label = _string(root, 'timeline_label');
    final mode = _string(root, 'mode');
    if (mode != 'fixed' && mode != 'estimated') {
      throw FormatException('Unknown beat sheet mode: $mode');
    }
    final actData = _list(root['acts'], 'acts');
    if (actData.isEmpty) throw const FormatException('No acts defined.');
    final minimum = mode == 'estimated'
        ? _positiveInt(root, 'minimum_beats_per_act')
        : 0;
    final pagesPerBeat = mode == 'estimated'
        ? _positiveInt(root, 'pages_per_beat')
        : 1;
    final total = mode == 'estimated'
        ? math.max(minimum * actData.length, (pages / pagesPerBeat).ceil())
        : 0;
    final acts = <StoryAct>[];
    final beats = <BeatDefinition>[];
    final ids = <String>{};
    final actIds = <String>{};
    for (var index = 0; index < actData.length; index++) {
      final data = _map(actData[index], 'act');
      final actId = _string(data, 'id');
      if (!actIds.add(actId)) throw FormatException('Duplicate act id: $actId');
      final act = StoryAct(
        _string(data, 'title'),
        _string(data, 'subtitle'),
        _color(data, 'color'),
        _color(data, 'dark_color'),
      );
      acts.add(act);
      final templates = _list(data['beats'], 'beats');
      if (templates.isEmpty ||
          (mode == 'estimated' && templates.length != minimum)) {
        throw FormatException(
          'Act $actId must contain ${mode == 'estimated' ? minimum : 'at least one'} beats.',
        );
      }
      final count = mode == 'estimated'
          ? total ~/ actData.length + (index < total % actData.length ? 1 : 0)
          : templates.length;
      final expanded = <YamlMap>[];
      for (var i = 0; i < templates.length; i++) {
        if (mode == 'estimated' && i == templates.length - 1) {
          for (var j = 0; j < count - templates.length; j++) {
            // Repeat beats are built separately below, keeping the final anchor last.
            expanded.add(
              YamlMap.wrap({
                'id': '${actId}_development_${j + 1}',
                'name': '${_string(root, 'repeat_name')} ${j + 1}',
                'summary': _string(root, 'repeat_summary'),
                'guidance': _string(root, 'repeat_guidance'),
              }),
            );
          }
        }
        expanded.add(_map(templates[i], 'beat'));
      }
      for (final data in expanded) {
        final beatId = _string(data, 'id');
        if (!ids.add(beatId)) {
          throw FormatException('Duplicate beat id: $beatId');
        }
        final number = beats.length + 1;
        final start = mode == 'estimated'
            ? ((number - 1) * pages ~/ total) + 1
            : 1;
        final end = mode == 'estimated'
            ? math.max(start, number * pages ~/ total)
            : 1;
        beats.add(
          BeatDefinition(
            id: beatId,
            number: number,
            name: _string(data, 'name'),
            act: act,
            targetPage: mode == 'fixed'
                ? _string(data, 'target_page')
                : start == end
                ? 'Page $start'
                : 'Pages $start - $end',
            percentage: mode == 'fixed'
                ? _string(data, 'percentage')
                : '${((number - 1) * 100 / total).round()}% - ${(number * 100 / total).round()}%',
            shortSummary: _string(data, 'summary'),
            guidance: _string(data, 'guidance'),
            icon: mode == 'fixed'
                ? _icon(_string(data, 'icon'))
                : Icons.movie_creation_outlined,
          ),
        );
      }
    }
    // Validate page labels at load time rather than during rendering.
    for (final beat in beats) {
      beat.estimatedSceneCount;
    }
    return BeatSheet(
      id: id,
      name: name,
      timelineLabel: label,
      acts: List.unmodifiable(acts),
      beats: List.unmodifiable(beats),
    );
  }
}

YamlMap _map(Object? value, String field) {
  if (value is! YamlMap) throw FormatException('$field must be a mapping.');
  return value;
}

YamlList _list(Object? value, String field) {
  if (value is! YamlList) throw FormatException('$field must be a list.');
  return value;
}

String _string(YamlMap map, String field) {
  final value = map[field];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$field must be a non-empty string.');
  }
  return value;
}

int _positiveInt(YamlMap map, String field) {
  final value = map[field];
  if (value is! int || value < 1 || value > 1000) {
    throw FormatException('$field must be an integer between 1 and 1000.');
  }
  return value;
}

Color _color(YamlMap map, String field) {
  final value = _string(map, field);
  if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(value)) {
    throw FormatException('$field must be a six-digit RGB color.');
  }
  return Color(0xFF000000 | int.parse(value, radix: 16));
}

const _icons = <String, IconData>{
  'movie_creation_outlined': Icons.movie_creation_outlined,
  'lightbulb_outline': Icons.lightbulb_outline,
  'home_work_outlined': Icons.home_work_outlined,
  'bolt': Icons.bolt,
  'question_mark_rounded': Icons.question_mark_rounded,
  'door_front_door_outlined': Icons.door_front_door_outlined,
  'favorite_border': Icons.favorite_border,
  'sports_esports_outlined': Icons.sports_esports_outlined,
  'hourglass_top_outlined': Icons.hourglass_top_outlined,
  'warning_amber_rounded': Icons.warning_amber_rounded,
  'heart_broken_outlined': Icons.heart_broken_outlined,
  'nights_stay_outlined': Icons.nights_stay_outlined,
  'wb_incandescent_outlined': Icons.wb_incandescent_outlined,
  'military_tech_outlined': Icons.military_tech_outlined,
  'play_arrow_rounded': Icons.play_arrow_rounded,
  'task_alt_outlined': Icons.task_alt_outlined,
  'verified_outlined': Icons.verified_outlined,
};

IconData _icon(String name) {
  final icon = _icons[name];
  if (icon == null) throw FormatException('Unknown beat icon: $name');
  return icon;
}
