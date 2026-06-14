part of 'player_bar_bloc.dart';

@immutable
abstract class PlayerBarState {}

class PlayerBarHidden extends PlayerBarState {}

class PlayerBarVisible extends PlayerBarState {
  final double height;
  PlayerBarVisible({this.height = 60.0});
}

class PlayerBarClosed extends PlayerBarState {}
