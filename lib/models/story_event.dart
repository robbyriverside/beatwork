class StoryEvent {
  final String id;
  String title;
  String description;
  String? beatId; // null when in the unassigned pool
  List<String> characters;
  String location;
  int orderIndex;
  final DateTime createdAt;

  StoryEvent({
    required this.id,
    required this.title,
    this.description = '',
    this.beatId,
    List<String>? characters,
    this.location = '',
    this.orderIndex = 0,
    DateTime? createdAt,
  })  : characters = characters ?? [],
        createdAt = createdAt ?? DateTime.now();

  StoryEvent copyWith({
    String? id,
    String? title,
    String? description,
    String? beatId,
    bool clearBeatId = false,
    List<String>? characters,
    String? location,
    int? orderIndex,
    DateTime? createdAt,
  }) {
    return StoryEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      beatId: clearBeatId ? null : (beatId ?? this.beatId),
      characters: characters ?? List.from(this.characters),
      location: location ?? this.location,
      orderIndex: orderIndex ?? this.orderIndex,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'beatId': beatId,
      'characters': characters,
      'location': location,
      'orderIndex': orderIndex,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory StoryEvent.fromJson(Map<String, dynamic> json) {
    return StoryEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      beatId: json['beatId'] as String?,
      characters: (json['characters'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      location: json['location'] as String? ?? '',
      orderIndex: json['orderIndex'] as int? ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
