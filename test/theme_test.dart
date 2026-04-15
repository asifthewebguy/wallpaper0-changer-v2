import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallpaper_changer/theme/app_colors.dart';
import 'package:wallpaper_changer/theme/app_theme.dart';

void main() {
  test('AppColors has correct base color', () {
    expect(AppColors.base, const Color(0xFF0A0A0F));
  });

  test('AppColors has correct primary accent', () {
    expect(AppColors.primary, const Color(0xFF6366F1));
  });

  test('AppTheme.dark returns a ThemeData with dark brightness', () {
    final theme = AppTheme.dark();
    expect(theme.brightness, Brightness.dark);
  });

  test('AppTheme.dark uses base color as scaffold background', () {
    final theme = AppTheme.dark();
    expect(theme.scaffoldBackgroundColor, AppColors.base);
  });

  test('AppTheme.dark colorScheme primary matches AppColors.primary', () {
    final theme = AppTheme.dark();
    expect(theme.colorScheme.primary, AppColors.primary);
  });

  test('AppTheme.dark colorScheme outline matches AppColors.border', () {
    final theme = AppTheme.dark();
    expect(theme.colorScheme.outline, AppColors.border);
  });

  test('AppTheme.dark cardTheme elevation is zero', () {
    final theme = AppTheme.dark();
    expect(theme.cardTheme.elevation, 0);
  });

  test('AppTheme.dark inputDecorationTheme is filled', () {
    final theme = AppTheme.dark();
    expect(theme.inputDecorationTheme.filled, true);
  });
}
