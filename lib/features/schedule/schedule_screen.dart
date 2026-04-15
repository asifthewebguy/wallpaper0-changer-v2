import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Schedule Screen', style: TextStyle(color: AppColors.textSecondary)),
    );
  }
}
