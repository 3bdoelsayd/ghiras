import 'package:get_it/get_it.dart';
import 'quran_repository.dart';
import 'quran_bloc.dart';

final getIt = GetIt.instance;

void setupQuranServiceLocator() {
  // Register repository
  getIt.registerSingleton<QuranRepository>(QuranRepository());

  // Register BLoC
  getIt.registerSingleton<QuranBloc>(
    QuranBloc(repository: getIt<QuranRepository>()),
  );
}
