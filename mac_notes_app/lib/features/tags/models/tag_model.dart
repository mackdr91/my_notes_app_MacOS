/// Represents a tag label for organizing notes.
class Tag {
  final String name;
  final int count;

  const Tag({
    required this.name,
    this.count = 0,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'count': count,
      };

  factory Tag.fromJson(Map<String, dynamic> json) => Tag(
        name: json['name'] as String,
        count: (json['count'] as int?) ?? 0,
      );
}
