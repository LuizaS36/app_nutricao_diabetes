import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta extraída do index.css do Figma Make.
class AppColors {
  static const teal = Color(0xFF80A32F); // --teal
  static const deep = Color(0xFF354219); // --deep
  static const mint = Color(0xFFECF39E); // --mint
  static const line = Color(0xFFE3E8D2); // --line
  static const muted = Color(0xFF75805C); // --muted
  static const lime = Color(0xFFC6D94C); // --lime
  static const leaf = Color(0xFFBAD17A); // --leaf
  static const olive = Color(0xFF6D8C27); // ícones sobre fundo claro
  static const bg = Color(0xFFF8F9F2);
  static const text = Color(0xFF3B4922);
  static const warn = Color(0xFFD0784E); // glicemia acima da meta
  static const danger = Color(0xFFD95D4D); // excluir / badges

  // Aliases usados nas telas (no CSS, "coral/amber/purple/blue" viraram tons de verde)
  static const coral = teal;
  static const amber = lime;
  static const purple = leaf;
  static const blue = leaf;
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: AppColors.teal).copyWith(
    primary: AppColors.teal,
    onPrimary: Colors.white,
    secondary: AppColors.leaf,
    surface: Colors.white,
    onSurface: AppColors.deep,
    outline: AppColors.line,
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme);

  OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: c, width: w),
      );

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    textTheme: GoogleFonts.manropeTextTheme(base.textTheme)
        .apply(bodyColor: AppColors.text, displayColor: AppColors.deep),
    dividerColor: AppColors.line,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      foregroundColor: AppColors.deep,
      elevation: 0,
      scrolledUnderElevation: 0,
      shape: Border(bottom: BorderSide(color: AppColors.line)),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.line),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.teal,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.olive,
        side: const BorderSide(color: AppColors.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.teal,
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      indicatorColor: AppColors.mint,
      labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
            fontSize: 11,
            fontWeight: s.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w600,
            color: s.contains(WidgetState.selected) ? AppColors.teal : AppColors.muted,
          )),
      iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
            color: s.contains(WidgetState.selected) ? AppColors.teal : AppColors.muted,
          )),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: border(const Color(0xFFDCE5D1)),
      enabledBorder: border(const Color(0xFFDCE5D1)),
      focusedBorder: border(AppColors.teal, 1.5),
      labelStyle: const TextStyle(fontSize: 13, color: AppColors.muted),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white,
      side: const BorderSide(color: AppColors.line),
      labelStyle: const TextStyle(fontSize: 11, color: AppColors.deep),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}
