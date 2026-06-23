import 'dart:convert';

class KhatmahModel {
  final String id;
  final String title;
  final DateTime startDate;
  final int durationDays;
  final int initialPage;
  int lastReadPage;
  final List<int> readPages;

  KhatmahModel({
    required this.id,
    required this.title,
    required this.startDate,
    this.durationDays = 30,
    this.initialPage = 1,
    this.lastReadPage = 0,
    this.readPages = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'startDate': startDate.toIso8601String(),
      'durationDays': durationDays,
      'initialPage': initialPage,
      'lastReadPage': lastReadPage,
      'readPages': readPages,
    };
  }

  factory KhatmahModel.fromMap(Map<String, dynamic> map) {
    // وظيفة مساعدة لتحويل أي قيمة لرقم صحيح بأمان
    int asInt(dynamic value, int defaultValue) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      return int.tryParse(value.toString()) ?? defaultValue;
    }

    return KhatmahModel(
      id: (map['id'] ?? '').toString(),
      title: (map['title'] ?? 'ختمة جديدة').toString(),
      startDate: map['startDate'] != null 
          ? DateTime.tryParse(map['startDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      durationDays: asInt(map['durationDays'], 30),
      initialPage: asInt(map['initialPage'], 1),
      lastReadPage: asInt(map['lastReadPage'], 0),
      readPages: map['readPages'] != null ? List<int>.from(map['readPages']) : [],
    );
  }

  String toJson() => json.encode(toMap());

  factory KhatmahModel.fromJson(String source) => KhatmahModel.fromMap(json.decode(source));

  double get progress {
    try {
      int total = (605 - initialPage);
      if (total <= 0) total = 604;
      return (readPages.length / total).clamp(0.0, 1.0);
    } catch (_) {
      return 0.0;
    }
  }
  
  int get pagesPerDay {
    try {
      int days = durationDays > 0 ? durationDays : 30;
      int totalPages = 605 - initialPage;
      if (totalPages <= 0) totalPages = 604;
      int ppd = (totalPages / days).ceil();
      return ppd > 0 ? ppd : 1;
    } catch (_) {
      return 20;
    }
  }

  int get targetPageForToday {
    try {
      int ppd = pagesPerDay;
      int portionsCompleted = (readPages.length / (ppd > 0 ? ppd : 20)).floor();
      int target = initialPage + ((portionsCompleted + 1) * ppd) - 1;
      return target.clamp(1, 604);
    } catch (_) {
      return (lastReadPage + 20).clamp(1, 604);
    }
  }

  int get remainingDays {
    try {
      int ppd = pagesPerDay;
      int pagesLeft = 604 - lastReadPage;
      if (pagesLeft <= 0) return 0;
      return (pagesLeft / (ppd > 0 ? ppd : 1)).ceil();
    } catch (_) {
      return 30;
    }
  }

  int get daysSinceStart => DateTime.now().difference(startDate).inDays + 1;
  int get expectedPagesRead => (daysSinceStart * pagesPerDay).clamp(0, 604);
  int get pagesBehind => (expectedPagesRead - readPages.length).clamp(0, 604);
  int get daysBehind => (pagesBehind / (pagesPerDay > 0 ? pagesPerDay : 1)).ceil();
  bool get isLagging => pagesBehind > 0;
}
