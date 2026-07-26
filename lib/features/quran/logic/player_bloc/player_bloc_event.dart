part of 'player_bloc_bloc.dart';

@immutable
class PlayerBlocEvent {
  const PlayerBlocEvent();
}

class StartPlaying extends PlayerBlocEvent {
  final Moshaf moshaf;
  final Reciter reciter;
  final int suraNumber;
  final BuildContext buildContext;
  // final String suraName;
  final List jsonData;
  final dynamic audioPlayer;
  final int initialIndex;

  const StartPlaying({
    required this.moshaf,
    required this.reciter,
    required this.suraNumber,
    required this.initialIndex,
    required this.buildContext,
    // required this.suraName,
    required this.jsonData,
    this.audioPlayer,
  });
}

class DownloadSurah extends PlayerBlocEvent {
  final Moshaf moshaf;
  final Reciter reciter;
  final String suraNumber;
  final String url;
  const DownloadSurah({
    required this.reciter,
    required this.moshaf,
    required this.suraNumber,
    required this.url, // required String surahName,
  });
}

class DownloadAllSurahs extends PlayerBlocEvent {
  final Moshaf moshaf;
  final Reciter reciter;
  const DownloadAllSurahs({
    required this.moshaf,
    required this.reciter,
  });
}

class ClosePlayerEvent extends PlayerBlocEvent {
  const ClosePlayerEvent();
}

class PausePlayer extends PlayerBlocEvent {
  const PausePlayer();
}
