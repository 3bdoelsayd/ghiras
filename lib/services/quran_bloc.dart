import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/quran_models.dart';
import 'quran_repository.dart';

// Events
abstract class QuranEvent extends Equatable {
  const QuranEvent();

  @override
  List<Object?> get props => [];
}

class InitializeQuranEvent extends QuranEvent {
  const InitializeQuranEvent();
}

class LoadSurahEvent extends QuranEvent {
  final int surahNumber;

  const LoadSurahEvent(this.surahNumber);

  @override
  List<Object?> get props => [surahNumber];
}

class LoadPageEvent extends QuranEvent {
  final int pageNumber;

  const LoadPageEvent(this.pageNumber);

  @override
  List<Object?> get props => [pageNumber];
}

class SearchQuranEvent extends QuranEvent {
  final String query;

  const SearchQuranEvent(this.query);

  @override
  List<Object?> get props => [query];
}

class LoadJuzEvent extends QuranEvent {
  final int juzNumber;

  const LoadJuzEvent(this.juzNumber);

  @override
  List<Object?> get props => [juzNumber];
}

// States
abstract class QuranState extends Equatable {
  const QuranState();

  @override
  List<Object?> get props => [];
}

class QuranInitial extends QuranState {
  const QuranInitial();
}

class QuranLoading extends QuranState {
  const QuranLoading();
}

class QuranLoaded extends QuranState {
  final List<Ayah> ayahs;
  final Surah? surah;
  final int? pageNumber;

  const QuranLoaded({
    required this.ayahs,
    this.surah,
    this.pageNumber,
  });

  @override
  List<Object?> get props => [ayahs, surah, pageNumber];
}

class SurahsLoaded extends QuranState {
  final List<Surah> surahs;

  const SurahsLoaded(this.surahs);

  @override
  List<Object?> get props => [surahs];
}

class QuranError extends QuranState {
  final String message;

  const QuranError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class QuranBloc extends Bloc<QuranEvent, QuranState> {
  final QuranRepository repository;

  QuranBloc({required this.repository}) : super(const QuranInitial()) {
    on<InitializeQuranEvent>(_onInitialize);
    on<LoadSurahEvent>(_onLoadSurah);
    on<LoadPageEvent>(_onLoadPage);
    on<SearchQuranEvent>(_onSearch);
    on<LoadJuzEvent>(_onLoadJuz);
  }

  Future<void> _onInitialize(
      InitializeQuranEvent event, Emitter<QuranState> emit) async {
    try {
      emit(const QuranLoading());
      await repository.initialize();
      final surahs = await repository.getAllSurahs();
      emit(SurahsLoaded(surahs));
    } catch (e) {
      emit(QuranError('Failed to initialize: $e'));
    }
  }

  Future<void> _onLoadSurah(
      LoadSurahEvent event, Emitter<QuranState> emit) async {
    try {
      emit(const QuranLoading());
      final ayahs = await repository.getSurahAyahs(event.surahNumber);
      final surah = await repository.getSurah(event.surahNumber);
      emit(QuranLoaded(ayahs: ayahs, surah: surah));
    } catch (e) {
      emit(QuranError('Failed to load surah: $e'));
    }
  }

  Future<void> _onLoadPage(
      LoadPageEvent event, Emitter<QuranState> emit) async {
    try {
      emit(const QuranLoading());
      final ayahs = await repository.getPageAyahs(event.pageNumber);
      emit(QuranLoaded(ayahs: ayahs, pageNumber: event.pageNumber));
    } catch (e) {
      emit(QuranError('Failed to load page: $e'));
    }
  }

  Future<void> _onSearch(
      SearchQuranEvent event, Emitter<QuranState> emit) async {
    try {
      emit(const QuranLoading());
      final results = await repository.searchQuran(event.query);
      emit(QuranLoaded(ayahs: results));
    } catch (e) {
      emit(QuranError('Search failed: $e'));
    }
  }

  Future<void> _onLoadJuz(
      LoadJuzEvent event, Emitter<QuranState> emit) async {
    try {
      emit(const QuranLoading());
      final ayahs = await repository.getJuzAyahs(event.juzNumber);
      emit(QuranLoaded(ayahs: ayahs));
    } catch (e) {
      emit(QuranError('Failed to load juz: $e'));
    }
  }
}
