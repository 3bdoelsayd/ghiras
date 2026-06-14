part of 'hadith_bloc.dart';

@immutable
abstract class HadithState extends Equatable {
  const HadithState();
  
  @override
  List<Object?> get props => [];
}

class HadithInitial extends HadithState {}

class HadithLoading extends HadithState {}

class HadithFetched extends HadithState {
  final List<dynamic> hadithBook;

  const HadithFetched(this.hadithBook);

  @override
  List<Object?> get props => [hadithBook];
}

class HadithDownloading extends HadithState {
  final String progress;
  final String fileName;
  
  const HadithDownloading(this.progress, this.fileName);

  @override
  List<Object?> get props => [progress, fileName];
}

class HadithError extends HadithState {
  final String message;
  
  const HadithError(this.message);

  @override
  List<Object?> get props => [message];
}
