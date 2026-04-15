import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class SourcesScreen extends StatelessWidget {
  const SourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Sources', style: TextStyle(color: AppColors.textSecondary)),
    );
  }
}
