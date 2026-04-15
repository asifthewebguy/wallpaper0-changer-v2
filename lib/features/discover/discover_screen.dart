import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Discover', style: TextStyle(color: AppColors.textSecondary)),
    );
  }
}
