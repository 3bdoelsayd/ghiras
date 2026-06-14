import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/bookmark_model.dart';
import 'bookmark_service.dart';

// Events
abstract class BookmarkEvent extends Equatable {
  const BookmarkEvent();

  @override
  List<Object?> get props => [];
}

class AddBookmarkEvent extends BookmarkEvent {
  final int surahNumber;
  final int ayahNumber;
  final int pageNumber;
  final String? notes;

  const AddBookmarkEvent({
    required this.surahNumber,
    required this.ayahNumber,
    required this.pageNumber,
    this.notes,
  });

  @override
  List<Object?> get props => [surahNumber, ayahNumber, pageNumber, notes];
}

class DeleteBookmarkEvent extends BookmarkEvent {
  final String bookmarkId;

  const DeleteBookmarkEvent(this.bookmarkId);

  @override
  List<Object?> get props => [bookmarkId];
}

class LoadBookmarksEvent extends BookmarkEvent {
  const LoadBookmarksEvent();
}

class UpdateProgressEvent extends BookmarkEvent {
  final int page;
  final int surah;
  final int ayah;
  final int juz;

  const UpdateProgressEvent({
    required this.page,
    required this.surah,
    required this.ayah,
    required this.juz,
  });

  @override
  List<Object?> get props => [page, surah, ayah, juz];
}

class LoadProgressEvent extends BookmarkEvent {
  const LoadProgressEvent();
}

// States
abstract class BookmarkState extends Equatable {
  const BookmarkState();

  @override
  List<Object?> get props => [];
}

class BookmarkInitial extends BookmarkState {
  const BookmarkInitial();
}

class BookmarkLoading extends BookmarkState {
  const BookmarkLoading();
}

class BookmarksLoaded extends BookmarkState {
  final List<Bookmark> bookmarks;

  const BookmarksLoaded(this.bookmarks);

  @override
  List<Object?> get props => [bookmarks];
}

class BookmarkAdded extends BookmarkState {
  final Bookmark bookmark;

  const BookmarkAdded(this.bookmark);

  @override
  List<Object?> get props => [bookmark];
}

class BookmarkDeleted extends BookmarkState {
  final String bookmarkId;

  const BookmarkDeleted(this.bookmarkId);

  @override
  List<Object?> get props => [bookmarkId];
}

class ProgressUpdated extends BookmarkState {
  final ReadingProgress progress;

  const ProgressUpdated(this.progress);

  @override
  List<Object?> get props => [progress];
}

class ProgressLoaded extends BookmarkState {
  final ReadingProgress? progress;

  const ProgressLoaded(this.progress);

  @override
  List<Object?> get props => [progress];
}

class BookmarkError extends BookmarkState {
  final String message;

  const BookmarkError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class BookmarkBloc extends Bloc<BookmarkEvent, BookmarkState> {
  final BookmarkService service;

  BookmarkBloc({required this.service}) : super(const BookmarkInitial()) {
    on<AddBookmarkEvent>(_onAddBookmark);
    on<DeleteBookmarkEvent>(_onDeleteBookmark);
    on<LoadBookmarksEvent>(_onLoadBookmarks);
    on<UpdateProgressEvent>(_onUpdateProgress);
    on<LoadProgressEvent>(_onLoadProgress);
  }

  Future<void> _onAddBookmark(
      AddBookmarkEvent event, Emitter<BookmarkState> emit) async {
    try {
      emit(const BookmarkLoading());
      final bookmark = await service.addBookmark(
        surahNumber: event.surahNumber,
        ayahNumber: event.ayahNumber,
        pageNumber: event.pageNumber,
        notes: event.notes,
      );
      emit(BookmarkAdded(bookmark));
      // Reload bookmarks
      add(const LoadBookmarksEvent());
    } catch (e) {
      emit(BookmarkError('فشل إضافة الإشارة المرجعية: $e'));
    }
  }

  Future<void> _onDeleteBookmark(
      DeleteBookmarkEvent event, Emitter<BookmarkState> emit) async {
    try {
      emit(const BookmarkLoading());
      await service.deleteBookmark(event.bookmarkId);
      emit(BookmarkDeleted(event.bookmarkId));
      // Reload bookmarks
      add(const LoadBookmarksEvent());
    } catch (e) {
      emit(BookmarkError('فشل حذف الإشارة المرجعية: $e'));
    }
  }

  Future<void> _onLoadBookmarks(
      LoadBookmarksEvent event, Emitter<BookmarkState> emit) async {
    try {
      emit(const BookmarkLoading());
      final bookmarks = await service.getAllBookmarks();
      emit(BookmarksLoaded(bookmarks));
    } catch (e) {
      emit(BookmarkError('فشل تحميل الإشارات المرجعية: $e'));
    }
  }

  Future<void> _onUpdateProgress(
      UpdateProgressEvent event, Emitter<BookmarkState> emit) async {
    try {
      await service.updateReadingProgress(
        page: event.page,
        surah: event.surah,
        ayah: event.ayah,
        juz: event.juz,
      );
      final progress = await service.getReadingProgress();
      if (progress != null) {
        emit(ProgressUpdated(progress));
      }
    } catch (e) {
      emit(BookmarkError('فشل تحديث التقدم: $e'));
    }
  }

  Future<void> _onLoadProgress(
      LoadProgressEvent event, Emitter<BookmarkState> emit) async {
    try {
      emit(const BookmarkLoading());
      final progress = await service.getReadingProgress();
      emit(ProgressLoaded(progress));
    } catch (e) {
      emit(BookmarkError('فشل تحميل التقدم: $e'));
    }
  }
}
