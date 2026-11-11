// Author: Domonick Mack
// Date: 2026-11-10
// Description: Data model representing a hashtag label and its note count.

/// Represents a tag label for organizing notes.
class Tag {
  final String name;
  final int count;

  const Tag({required this.name, this.count = 0});

  Map<String, dynamic> toJson() => {'name': name, 'count': count};

  factory Tag.fromJson(Map<String, dynamic> json) =>
      Tag(name: json['name'] as String, count: (json['count'] as int?) ?? 0);
}
