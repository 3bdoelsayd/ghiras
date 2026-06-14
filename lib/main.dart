import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'services/quran_repository.dart';
import 'services/quran_bloc.dart';
import 'widgets/mushaf_page_view.dart';
import 'widgets/surah_list_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
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
            ),
            useMaterial3: true,
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
    context.read<QuranBloc>().add(const InitializeQuranEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('غِراس'),
        elevation: 0,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          MushafPageView(),
          SurahListView(),
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
        ],
      ),
    );
  }
}
