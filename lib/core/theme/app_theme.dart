import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Industrial light theme — purpose-built for warehouse PDT use.
///
/// Design principles:
///  • Clean, high-contrast light background for bright warehouse lighting
///  • Steel blue primary — professional / industrial
///  • Amber accent — high-visibility CTAs and scan fields
///  • 64px minimum button height — glove-friendly touch targets
///  • Roboto Mono for scanned values — machine-readable clarity
///  • 8px corner radius — functional, not decorative
class AppTheme {
  AppTheme._();

  // ─── Color Palette ──────────────────────────────────────────────────────────

  /// Primary — deep industrial steel blue
  static const Color primary       = Color(0xFF1B4F8A);
  static const Color primaryLight  = Color(0xFF2B6BC2);
  static const Color primaryDark   = Color(0xFF0D3260);

  /// Accent — high-visibility amber (scan fields, primary actions)
  static const Color amber         = Color(0xFFE09600);
  static const Color amberLight    = Color(0xFFFBF0D0);

  /// Backgrounds
  static const Color bgScaffold    = Color(0xFFF0F4F8);   // cool light grey
  static const Color bgSurface     = Color(0xFFFFFFFF);   // card surface
  static const Color bgElevated    = Color(0xFFE8EDF3);   // elevated / input bg
  static const Color bgBorder      = Color(0xFFCDD5DF);   // subtle border

  /// Semantic
  static const Color success       = Color(0xFF1A7A4A);
  static const Color successLight  = Color(0xFFD4EDDA);
  static const Color warning       = Color(0xFFC47D00);
  static const Color warningLight  = Color(0xFFFFF3CD);
  static const Color danger        = Color(0xFFC0392B);
  static const Color dangerLight   = Color(0xFFFFE5E3);
  static const Color info          = Color(0xFF1A5AA8);
  static const Color infoLight     = Color(0xFFD0E4FF);

  /// Text
  static const Color textPrimary   = Color(0xFF1C2B3A);
  static const Color textSecondary = Color(0xFF5C6D7A);
  static const Color textDisabled  = Color(0xFFABBAC7);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ─── Typography ─────────────────────────────────────────────────────────────

  static TextTheme get _textTheme => GoogleFonts.interTextTheme(
    const TextTheme(
      displayLarge:  TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: textPrimary, letterSpacing: -0.5),
      displayMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: textPrimary),
      displaySmall:  TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: textPrimary),
      headlineLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: textPrimary),
      headlineMedium:TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
      headlineSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
      titleLarge:    TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
      titleMedium:   TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
      titleSmall:    TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textSecondary),
      bodyLarge:     TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: textPrimary, height: 1.5),
      bodyMedium:    TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: textPrimary, height: 1.5),
      bodySmall:     TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: textSecondary),
      labelLarge:    TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary, letterSpacing: 0.5),
      labelMedium:   TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textSecondary),
      labelSmall:    TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: textDisabled, letterSpacing: 0.5),
    ),
  );

  /// Roboto Mono style for scanned barcodes / qty values
  static TextStyle get scanValueStyle => GoogleFonts.robotoMono(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: 1.0,
  );

  static TextStyle get scanHintStyle => GoogleFonts.robotoMono(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );

  // ─── Dimensions ─────────────────────────────────────────────────────────────

  static const double buttonHeight    = 64.0;  // glove-friendly
  static const double listItemHeight  = 72.0;  // glove-friendly list rows
  static const double inputHeight     = 60.0;  // tall inputs, easy to tap
  static const double borderRadius    = 8.0;
  static const double cardRadius      = 10.0;
  static const double borderWidth     = 1.5;
  static const double horizontalPad   = 16.0;

  // ─── Light Theme ────────────────────────────────────────────────────────────

  static ThemeData get lightTheme {
    const colorScheme = ColorScheme.light(
      primary:          primary,
      onPrimary:        textOnPrimary,
      secondary:        amber,
      onSecondary:      textPrimary,
      error:            danger,
      onError:          Colors.white,
      surface:          bgSurface,
      onSurface:        textPrimary,
      surfaceContainerHighest: bgElevated,
      outline:          bgBorder,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bgScaffold,
      textTheme: _textTheme,

      // ─── AppBar ───────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        toolbarHeight: 64,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white, size: 24),
        actionsIconTheme: const IconThemeData(color: Colors.white, size: 24),
      ),

      // ─── Elevated Button (primary amber CTA) ──────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: bgBorder,
          disabledForegroundColor: textDisabled,
          minimumSize: const Size(double.infinity, buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          elevation: 0,
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // ─── Outlined Button (secondary action) ───────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: borderWidth),
          minimumSize: const Size(double.infinity, buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ─── Text Button ──────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(0, 48),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ─── Input fields ─────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: bgBorder, width: borderWidth),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: bgBorder, width: borderWidth),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: primary, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: danger, width: borderWidth),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: danger, width: 2.0),
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textDisabled,
        ),
        errorStyle: GoogleFonts.inter(
          fontSize: 12,
          color: danger,
        ),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
      ),

      // ─── Card ─────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 0,
        color: bgSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: const BorderSide(color: bgBorder, width: 1.0),
        ),
        margin: EdgeInsets.zero,
      ),

      // ─── Chip ─────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: bgElevated,
        selectedColor: primary,
        labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),

      // ─── Divider ──────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: bgBorder,
        thickness: 1,
        space: 1,
      ),

      // ─── List Tile ────────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minVerticalPadding: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        tileColor: bgSurface,
      ),

      // ─── Bottom Sheet ─────────────────────────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: bgSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        elevation: 8,
      ),

      // ─── Snackbar ─────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        contentTextStyle: GoogleFonts.inter(fontSize: 14, color: Colors.white),
        // Most PDT screens dock a persistent action bar (Finish/Complete/
        // Back) inside the screen body rather than Scaffold's own
        // bottomNavigationBar slot, so a snackbar floating with the default
        // ~8px margin lands right on top of those buttons. Lifting it clear
        // of a typical ~72-80dp button bar fixes that everywhere at once.
        margin: EdgeInsets.only(left: 16, right: 16, bottom: 96),
        duration: Duration(seconds: 3),
      ),

      // ─── Progress Indicator ───────────────────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primary,
      ),

      // ─── Icon ─────────────────────────────────────────────────────────────
      iconTheme: const IconThemeData(color: textSecondary, size: 22),
    );
  }
}
