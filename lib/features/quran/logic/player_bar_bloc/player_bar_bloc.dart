import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';

part 'player_bar_event.dart';
part 'player_bar_state.dart';

class PlayerBarBloc extends Bloc<PlayerBarEvent, PlayerBarState> {
  PlayerBarBloc() : super(PlayerBarHidden()) {
    on<ShowBarEvent>((event, emit) => emit(PlayerBarVisible(height: 60)));
    on<HideBarEvent>((event, emit) => emit(PlayerBarHidden()));
    on<MinimizeBarEvent>((event, emit) => emit(PlayerBarVisible(height: 60)));
    on<ExtendBarEvent>((event, emit) => emit(PlayerBarVisible(height: 1000))); // High value for full screen
    on<CloseBarEvent>((event, emit) => emit(PlayerBarClosed()));
  }
}
