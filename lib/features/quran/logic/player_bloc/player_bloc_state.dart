part of 'player_bloc_bloc.dart';

@immutable
class PlayerBlocState {
  const PlayerBlocState();
}

class PlayerBlocInitial extends PlayerBlocState {
  const PlayerBlocInitial();
}

class PlayerBlocPlaying extends PlayerBlocState {
  final Moshaf moshaf;
  final Reciter reciter;
  final int suraNumber;
  // final String suraName;
  final dynamic jsonData;
  final AudioPlayer audioPlayer;
  final List surahNumbers;
  final dynamic playList;

  // final bool isHidden;
  const PlayerBlocPlaying({
    required this.moshaf,
    required this.reciter,
    required this.suraNumber,
    // required this.suraName,
    required this.jsonData,
    required this.audioPlayer,
    required this.surahNumbers,
    required this.playList,
    // required this.isHidden
  });
}

class PlayerBlocPaused extends PlayerBlocState {
  const PlayerBlocPaused();
}

class PlayerBlocClosed extends PlayerBlocState {
  const PlayerBlocClosed();
}

class PlayerBlocError extends PlayerBlocState {
  final String message;
  const PlayerBlocError(this.message);
}
