enum EmotionalCharge {
  positive('Positive (+)', '+', 0xFF10B981),
  negative('Negative (-)', '-', 0xFFEF4444),
  neutral('Neutral (o)', 'o', 0xFF6B7280),
  shift('Shift (+/-)', '⇄', 0xFFF59E0B);

  final String label;
  final String symbol;
  final int colorValue;

  const EmotionalCharge(this.label, this.symbol, this.colorValue);
}

class StoryEvent {
  final String id;
  String title;
  String description;
  String? beatId; // null when in the unassigned pool
  EmotionalCharge emotionalCharge;
  List<String> characters;
  String location;
  int orderIndex;
  final DateTime createdAt;

  StoryEvent({
    required this.id,
    required this.title,
    this.description = '',
    this.beatId,
    this.emotionalCharge = EmotionalCharge.neutral,
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
    EmotionalCharge? emotionalCharge,
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
      emotionalCharge: emotionalCharge ?? this.emotionalCharge,
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
      'emotionalCharge': emotionalCharge.name,
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
      emotionalCharge: EmotionalCharge.values.firstWhere(
        (e) => e.name == json['emotionalCharge'],
        orElse: () => EmotionalCharge.neutral,
      ),
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
