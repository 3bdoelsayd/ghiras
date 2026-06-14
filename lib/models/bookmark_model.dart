import 'package:equatable/equatable.dart';

class Bookmark extends Equatable {
  final String id;
  final int surahNumber;
  final int ayahNumber;
  final int pageNumber;
  final DateTime createdAt;
  final String? notes;

  const Bookmark({
    required this.id,
    required this.surahNumber,
    required this.ayahNumber,
    required this.pageNumber,
    required this.createdAt,
    this.notes,
  });

  @override
  List<Object?> get props => [
    id,
    surahNumber,
    ayahNumber,
    pageNumber,
    createdAt,
    notes,
  ];

  Map<String, dynamic> toJson() => {
    'id': id,
    'surahNumber': surahNumber,
    'ayahNumber': ayahNumber,
    'pageNumber': pageNumber,
    'createdAt': createdAt.toIso8601String(),
    'notes': notes,
  };

  factory Bookmark.fromJson(Map<String, dynamic> json) => Bookmark(
    id: json['id'] as String,
    surahNumber: json['surahNumber'] as int,
    ayahNumber: json['ayahNumber'] as int,
    pageNumber: json['pageNumber'] as int,
    createdAt: DateTime.parse(json['createdAt'] as String),
    notes: json['notes'] as String?,
  );
}

class ReadingProgress extends Equatable {
  final int lastReadPage;
  final int lastReadSurah;
  final int lastReadAyah;
  final DateTime lastReadTime;
  final int totalPagesRead;
  final int currentJuz;

  const ReadingProgress({
    required this.lastReadPage,
    required this.lastReadSurah,
    required this.lastReadAyah,
    required this.lastReadTime,
    required this.totalPagesRead,
    required this.currentJuz,
  });

  @override
  List<Object?> get props => [
    lastReadPage,
    lastReadSurah,
    lastReadAyah,
    lastReadTime,
    totalPagesRead,
    currentJuz,
  ];

  Map<String, dynamic> toJson() => {
    'lastReadPage': lastReadPage,
    'lastReadSurah': lastReadSurah,
    'lastReadAyah': lastReadAyah,
    'lastReadTime': lastReadTime.toIso8601String(),
    'totalPagesRead': totalPagesRead,
    'currentJuz': currentJuz,
  };

  factory ReadingProgress.fromJson(Map<String, dynamic> json) => ReadingProgress(
    lastReadPage: json['lastReadPage'] as int,
    lastReadSurah: json['lastReadSurah'] as int,
    lastReadAyah: json['lastReadAyah'] as int,
    lastReadTime: DateTime.parse(json['lastReadTime'] as String),
    totalPagesRead: json['totalPagesRead'] as int,
    currentJuz: json['currentJuz'] as int,
  );
}
