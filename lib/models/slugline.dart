class Slugline {
  static const prefixes = ['INT.', 'EXT.', 'INT./EXT.', 'EXT./INT.', 'I/E.'];
  static const times = [
    'DAY',
    'NIGHT',
    'DAWN',
    'DUSK',
    'MORNING',
    'AFTERNOON',
    'EVENING',
    'CONTINUOUS',
    'LATER',
  ];

  final String prefix;
  final String location;
  final String time;

  const Slugline({this.prefix = 'INT.', this.location = '', this.time = 'DAY'});

  static Slugline? parse(String value) {
    final match = RegExp(
      r'^\s*(INT\./EXT\.|EXT\./INT\.|INT\.|EXT\.|I/E\.)\s+(?:(.*)\s+)?-\s+(\S.*)\s*$',
      caseSensitive: false,
    ).firstMatch(value);
    if (match == null) return null;
    return Slugline(
      prefix: match.group(1)!.toUpperCase(),
      location: match.group(2)?.trim() ?? '',
      time: match.group(3)!.trim().toUpperCase(),
    );
  }

  String format() {
    final trimmedLocation = location.trim().toUpperCase();
    return trimmedLocation.isEmpty
        ? '$prefix - $time'
        : '$prefix $trimmedLocation - $time';
  }
}
