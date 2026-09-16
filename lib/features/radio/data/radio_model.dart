class QuranRadio {
  final int id;
  final String name;
  final String url;

  QuranRadio({
    required this.id,
    required this.name,
    required this.url,
  });

  factory QuranRadio.fromJson(Map<String, dynamic> json) {
    return QuranRadio(
      id: json['id'] as int,
      name: json['name'] as String,
      url: json['url'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
    };
  }
}
