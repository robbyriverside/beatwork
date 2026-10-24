import 'package:uuid/uuid.dart';

class SceneVersion {
  final String id;
  final int versionNumber;
  String label;
  String slugline;
  String summary;
  String scriptContent;
  String notes;
  final DateTime createdAt;

  SceneVersion({
    required this.id,
    required this.versionNumber,
    this.label = '',
    this.slugline = 'INT. UNKNOWN LOCATION - DAY',
    this.summary = '',
    this.scriptContent = '',
    this.notes = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  SceneVersion copyWith({
    String? id,
    int? versionNumber,
    String? label,
    String? slugline,
    String? summary,
    String? scriptContent,
    String? notes,
    DateTime? createdAt,
  }) {
    return SceneVersion(
      id: id ?? this.id,
      versionNumber: versionNumber ?? this.versionNumber,
      label: label ?? this.label,
      slugline: slugline ?? this.slugline,
      summary: summary ?? this.summary,
      scriptContent: scriptContent ?? this.scriptContent,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'versionNumber': versionNumber,
      'label': label,
      'slugline': slugline,
      'summary': summary,
      'scriptContent': scriptContent,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SceneVersion.fromJson(Map<String, dynamic> json) {
    return SceneVersion(
      id: json['id'] as String,
      versionNumber: json['versionNumber'] as int? ?? 1,
      label: json['label'] as String? ?? 'Draft 1',
      slugline: json['slugline'] as String? ?? 'INT. UNKNOWN LOCATION - DAY',
      summary: json['summary'] as String? ?? '',
      scriptContent: json['scriptContent'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class Scene {
  final String id;
  final String beatId;
  String title;
  int timelineOrder;
  List<String> mappedEventIds;
  List<SceneVersion> versions;
  String? activeVersionId;

  Scene({
    required this.id,
    required this.beatId,
    required this.title,
    this.timelineOrder = 0,
    List<String>? mappedEventIds,
    List<SceneVersion>? versions,
    this.activeVersionId,
  })  : mappedEventIds = mappedEventIds ?? [],
        versions = versions ?? [] {
    if (this.versions.isEmpty) {
      final initialVersion = SceneVersion(
        id: const Uuid().v4(),
        versionNumber: 1,
        label: 'Version 1 (Initial Draft)',
        slugline: 'INT. UNTITLED SCENE - DAY',
        summary: title,
        scriptContent: 'Action description begins here...',
      );
      this.versions.add(initialVersion);
      activeVersionId = initialVersion.id;
    } else if (activeVersionId == null ||
        !this.versions.any((v) => v.id == activeVersionId)) {
      activeVersionId = this.versions.last.id;
    }
  }

  SceneVersion get activeVersion {
    if (versions.isEmpty) {
      final v = SceneVersion(
        id: const Uuid().v4(),
        versionNumber: 1,
        label: 'Draft 1',
      );
      versions.add(v);
      activeVersionId = v.id;
      return v;
    }
    return versions.firstWhere(
      (v) => v.id == activeVersionId,
      orElse: () => versions.last,
    );
  }

  SceneVersion get latestVersion {
    if (versions.isEmpty) return activeVersion;
    return versions.reduce((a, b) => a.versionNumber > b.versionNumber ? a : b);
  }

  SceneVersion createNewVersion({
    String? label,
    String? slugline,
    String? summary,
    String? scriptContent,
    String? notes,
  }) {
    final nextNum = versions.isEmpty
        ? 1
        : versions
                .map((v) => v.versionNumber)
                .reduce((a, b) => a > b ? a : b) +
            1;

    final current = activeVersion;
    final newVersion = SceneVersion(
      id: const Uuid().v4(),
      versionNumber: nextNum,
      label: label ?? 'Version $nextNum',
      slugline: slugline ?? current.slugline,
      summary: summary ?? current.summary,
      scriptContent: scriptContent ?? current.scriptContent,
      notes: notes ?? 'Revision created based on Version ${current.versionNumber}',
    );

    versions.add(newVersion);
    activeVersionId = newVersion.id; // Writer uses latest version by default
    return newVersion;
  }

  Scene copyWith({
    String? id,
    String? beatId,
    String? title,
    int? timelineOrder,
    List<String>? mappedEventIds,
    List<SceneVersion>? versions,
    String? activeVersionId,
  }) {
    return Scene(
      id: id ?? this.id,
      beatId: beatId ?? this.beatId,
      title: title ?? this.title,
      timelineOrder: timelineOrder ?? this.timelineOrder,
      mappedEventIds: mappedEventIds ?? List.from(this.mappedEventIds),
      versions: versions ?? List.from(this.versions),
      activeVersionId: activeVersionId ?? this.activeVersionId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'beatId': beatId,
      'title': title,
      'timelineOrder': timelineOrder,
      'mappedEventIds': mappedEventIds,
      'versions': versions.map((v) => v.toJson()).toList(),
      'activeVersionId': activeVersionId,
    };
  }

  factory Scene.fromJson(Map<String, dynamic> json) {
    final vList = (json['versions'] as List<dynamic>?)
            ?.map((e) => SceneVersion.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return Scene(
      id: json['id'] as String,
      beatId: json['beatId'] as String,
      title: json['title'] as String,
      timelineOrder: json['timelineOrder'] as int? ?? 0,
      mappedEventIds: (json['mappedEventIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      versions: vList,
      activeVersionId: json['activeVersionId'] as String?,
    );
  }
}
