part of 'hadith_bloc.dart';

@immutable
class HadithEvent {}

class DownloadHadithBook extends HadithEvent {
  final String filename;

  DownloadHadithBook({required this.filename});
}

class GetHadithBook extends HadithEvent {
  final String filename;

  GetHadithBook({required this.filename});
}
