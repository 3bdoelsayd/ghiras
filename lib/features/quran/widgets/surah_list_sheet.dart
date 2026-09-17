import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_container.dart';

class SurahListSheet extends StatefulWidget {
  final Function(int) onSurahTap;
  const SurahListSheet({super.key, required this.onSurahTap});

  @override
  State<SurahListSheet> createState() => _SurahListSheetState();
}

class _SurahListSheetState extends State<SurahListSheet> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'فهرس السور',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
          ),
          const SizedBox(height: 15),
          GlassContainer(
            opacity: 0.1,
            blur: 10,
            borderRadius: 15,
            child: TextField(
              onChanged: (val) => setState(() => searchQuery = val),
              decoration: const InputDecoration(
                hintText: 'ابحث عن سورة...',
                prefixIcon: Icon(Icons.search),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 15),
          Expanded(
            child: ListView.builder(
              itemCount: 114,
              itemBuilder: (context, index) {
                final sNum = index + 1;
                final name = quran.getSurahNameArabic(sNum);
                if (searchQuery.isNotEmpty && !name.contains(searchQuery)) {
                  return const SizedBox.shrink();
                }
                
                return ListTile(
                  onTap: () {
                    final page = quran.getSurahPages(sNum)[0];
                    widget.onSurahTap(page);
                    Navigator.pop(context);
                  },
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(sNum.toString(), style: const TextStyle(color: AppColors.primary, fontSize: 12)),
                  ),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${quran.getVerseCount(sNum)} آية • ص ${quran.getSurahPages(sNum)[0]}', style: const TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
