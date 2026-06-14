// تحديث main.dart للاستخدام الكامل للنظام الجديد
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:get_it/get_it.dart';
import 'services/quran_repository.dart';
import 'services/quran_bloc.dart';
import 'services/bookmark_service.dart';
import 'widgets/mushaf_page_view.dart';
import 'widgets/surah_list_view.dart';
import 'widgets/search_quran_widget.dart';

const getIt = GetIt.instance;

void setupServiceLocator() {
  // Register repository
  getIt.registerSingleton<QuranRepository>(QuranRepository());

  // Register BLoC
  getIt.registerSingleton<QuranBloc>(
    QuranBloc(repository: getIt<QuranRepository>()),
  );

  // Register Bookmark Service
  getIt.registerSingleton<BookmarkService>(BookmarkService());
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Setup service locator
  setupServiceLocator();
  
  // Initialize services
  await getIt<QuranRepository>().initialize();
  await getIt<BookmarkService>().initialize();
  
  runApp(const GhirasApp());
}

class GhirasApp extends StatelessWidget {
  const GhirasApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, child) {
        return MaterialApp(
          title: 'غِراس - Ghiras',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primaryColor: const Color(0xFF1A5B3D),
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1A5B3D),
              elevation: 0,
              centerTitle: true,
              iconTheme: IconThemeData(color: Colors.white),
            ),
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1A5B3D),
              brightness: Brightness.light,
            ),
          ),
          darkTheme: ThemeData(
            primaryColor: const Color(0xFF1A5B3D),
            scaffoldBackgroundColor: const Color(0xFF121212),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1A5B3D),
              elevation: 0,
            ),
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1A5B3D),
              brightness: Brightness.dark,
            ),
          ),
          home: const GhirasHomePage(),
        );
      },
    );
  }
}

class GhirasHomePage extends StatefulWidget {
  const GhirasHomePage({Key? key}) : super(key: key);

  @override
  State<GhirasHomePage> createState() => _GhirasHomePageState();
}

class _GhirasHomePageState extends State<GhirasHomePage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Initialize Quran data
    context.read<QuranBloc>().add(const InitializeQuranEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('غِراس'),
        elevation: 0,
        actions: [
          if (_selectedIndex == 1)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => _showSearchDialog(),
            ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          BlocProvider<QuranBloc>.value(
            value: getIt<QuranBloc>(),
            child: const MushafPageView(),
          ),
          BlocProvider<QuranBloc>.value(
            value: getIt<QuranBloc>(),
            child: const SurahListView(),
          ),
          BlocProvider<QuranBloc>.value(
            value: getIt<QuranBloc>(),
            child: const SearchQuranWidget(),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF1A5B3D),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'المصحف',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'السور',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'البحث',
          ),
        ],
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('البحث في القرآن'),
        content: const SearchQuranWidget(),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }
}
