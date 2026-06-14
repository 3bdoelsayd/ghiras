class AthkarCategory {
  final int id;
  final String category;
  final List<AthkarItem> array;

  AthkarCategory({
    required this.id,
    required this.category,
    required this.array,
  });

  factory AthkarCategory.fromJson(Map<String, dynamic> json) {
    return AthkarCategory(
      id: json['id'] ?? 0,
      category: json['category'] ?? '',
      array: (json['array'] as List? ?? []).map((i) => AthkarItem.fromJson(i)).toList(),
    );
  }
}

class AthkarItem {
  final int id;
  final String text;
  final int count;

  AthkarItem({
    required this.id,
    required this.text,
    required this.count,
  });

  factory AthkarItem.fromJson(Map<String, dynamic> json) {
    return AthkarItem(
      id: json['id'] ?? 0,
      text: json['text'] ?? '',
      count: json['count'] ?? 1,
    );
  }
}
