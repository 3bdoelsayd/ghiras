import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class SettingSectionHeader extends StatelessWidget {
  final String title;
  const SettingSectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 16),
      child: Text(
        title, 
        textAlign: TextAlign.right,
        style: const TextStyle(
          fontSize: 16, 
          fontWeight: FontWeight.w900, 
          color: AppColors.primary, 
          fontFamily: 'Cairo'
        )
      ),
    );
  }
}
