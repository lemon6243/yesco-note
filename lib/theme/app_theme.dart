// ============================================================
// AppTheme (앱 색상/디자인 테마)
// ------------------------------------------------------------
// 선택된 디자인 시안(전문적인 구조 + 코랄/틸의 따뜻한 색감)을
// 코드로 옮긴 테마 정의입니다. 라이트모드/다크모드 두 가지를
// 모두 제공합니다.
// ============================================================

import 'package:flutter/material.dart';

class AppColors {
  // 브랜드 메인 컬러: 코랄(주황빛 산호색)과 틸(청록색)
  static const Color coral = Color(0xFFFF7F5C);
  static const Color teal = Color(0xFF00A896);
  static const Color gold = Color(0xFFF6B93B);
  static const Color lavender = Color(0xFF9B8CF2);

  // 우선순위 매트릭스 사분면 색상
  static const Color quadrantUrgentImportant = coral; // 긴급&중요
  static const Color quadrantImportantOnly = teal; // 중요만
  static const Color quadrantUrgentOnly = gold; // 긴급만
  static const Color quadrantNeither = lavender; // 둘 다 낮음
}

class AppTheme {
  // 밝은(라이트) 테마
  static ThemeData light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF7F7FA),
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.coral,
      brightness: Brightness.light,
      primary: AppColors.coral,
      secondary: AppColors.teal,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: Color(0xFF2D3436),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.coral,
      foregroundColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.coral,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF1F2F6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );

  // 어두운(다크) 테마
  static ThemeData dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF1A1D21),
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.coral,
      brightness: Brightness.dark,
      primary: AppColors.coral,
      secondary: AppColors.teal,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: Colors.white,
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF25292E),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xFF25292E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.coral,
      foregroundColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.coral,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2C3136),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}
