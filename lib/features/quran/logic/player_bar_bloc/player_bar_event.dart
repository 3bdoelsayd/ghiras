part of 'player_bar_bloc.dart';

@immutable
abstract class PlayerBarEvent {}

class ShowBarEvent extends PlayerBarEvent {}

class HideBarEvent extends PlayerBarEvent {}

class MinimizeBarEvent extends PlayerBarEvent {}

class ExtendBarEvent extends PlayerBarEvent {}

class CloseBarEvent extends PlayerBarEvent {}
