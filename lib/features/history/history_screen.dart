import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('History Screen', style: TextStyle(color: AppColors.textSecondary)),
    );
  }
}
