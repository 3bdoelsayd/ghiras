import 'dart:convert';

class KhatmahModel {
  final String id;
  final String title;
  final DateTime startDate;
  final int durationDays;
  int lastReadPage;
  final List<int> readPages;

  KhatmahModel({
    required this.id,
    required this.title,
    required this.startDate,
    required this.durationDays,
    this.lastReadPage = 0,
    this.readPages = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'startDate': startDate.toIso8601String(),
      'durationDays': durationDays,
      'lastReadPage': lastReadPage,
      'readPages': readPages,
    };
  }

  factory KhatmahModel.fromMap(Map<String, dynamic> map) {
    return KhatmahModel(
      id: map['id'],
      title: map['title'],
      startDate: DateTime.parse(map['startDate']),
      durationDays: map['durationDays'],
      lastReadPage: map['lastReadPage'] ?? 0,
      readPages: List<int>.from(map['readPages'] ?? []),
    );
  }

  String toJson() => json.encode(toMap());

  factory KhatmahModel.fromJson(String source) => KhatmahModel.fromMap(json.decode(source));

  double get progress => readPages.length / 604;
  
  int get pagesPerDay => (604 / durationDays).ceil();

  int get targetPageForToday => (lastReadPage + pagesPerDay).clamp(1, 604);

  int get remainingDays {
    int pagesLeft = 604 - lastReadPage;
    if (pagesLeft <= 0) return 0;
    int days = (pagesLeft / pagesPerDay).ceil();
    return days;
  }

  int get daysSinceStart => DateTime.now().difference(startDate).inDays + 1;

  int get expectedPagesRead => (daysSinceStart * pagesPerDay).clamp(0, 604);

  int get pagesBehind {
    int behind = expectedPagesRead - readPages.length;
    return behind < 0 ? 0 : behind;
  }

  int get daysBehind => (pagesBehind / pagesPerDay).ceil();

  bool get isLagging => pagesBehind > 0;
}
