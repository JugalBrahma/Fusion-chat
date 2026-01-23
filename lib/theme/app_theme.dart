import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors
  static const Color primaryColor = Color(0xFF3B82F6);
  static const Color scaffoldBackgroundColor = Color(0xFFF8FAFC);
  static const Color appBarBackgroundColor = Colors.white;
  static const Color appBarForegroundColor = Color(0xFF1E293B);
  static const Color cardColor = Colors.white;
  static const Color inputFillColor = Color(0xFFF8FAFC);
  static const Color inputBorderColor = Color(0xFFE2E8F0);
  static const Color inputFocusedBorderColor = Color(0xFF3B82F6);
  static const Color buttonForegroundColor = Colors.white;
  static const Color textButtonColor = Color(0xFF3B82F6);
  static const Color tabBarLabelColor = Color(0xFF3B82F6);
  static const Color tabBarUnselectedLabelColor = Color(0xFF64748B);
  static const Color snackBarBackgroundColor = Color(0xFF1E293B);
  static const Color dialogBackgroundColor = Colors.white;
  static const Color iconColor = Color(0xFF64748B);
  static const Color labelColor = Color(0xFF64748B);
  static const Color headlineColor = Color(0xFF1E293B);
  static const Color bodyTextColor = Color(0xFF374151);
  static const Color bodyMediumColor = Color(0xFF64748B);

  // Text Styles
  static TextStyle get appBarTextStyle => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: appBarForegroundColor,
  );

  static TextStyle get labelTextStyle => GoogleFonts.inter(color: labelColor);

  static TextStyle get elevatedButtonTextStyle => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static TextStyle get textButtonTextStyle => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static TextStyle get tabBarLabelStyle => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static TextStyle get tabBarUnselectedLabelStyle => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  static TextStyle get snackBarTextStyle => GoogleFonts.inter(color: Colors.white);

  static TextStyle get dialogTitleTextStyle => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: headlineColor,
  );

  static TextStyle get dialogContentTextStyle => GoogleFonts.inter(
    fontSize: 14,
    color: bodyMediumColor,
  );

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: appBarBackgroundColor,
        foregroundColor: appBarForegroundColor,
        elevation: 0,
        titleTextStyle: appBarTextStyle,
        iconTheme: IconThemeData(
          color: iconColor,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: cardColor,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: inputBorderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: inputBorderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: inputFocusedBorderColor, width: 1.5),
        ),
        labelStyle: labelTextStyle,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: buttonForegroundColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: elevatedButtonTextStyle,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: textButtonColor,
          textStyle: textButtonTextStyle,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelStyle: tabBarLabelStyle,
        unselectedLabelStyle: tabBarUnselectedLabelStyle,
        labelColor: tabBarLabelColor,
        unselectedLabelColor: tabBarUnselectedLabelColor,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(
            color: tabBarLabelColor,
            width: 2,
          ),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: snackBarBackgroundColor,
        contentTextStyle: snackBarTextStyle,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: dialogBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: dialogTitleTextStyle,
        contentTextStyle: dialogContentTextStyle,
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        headlineLarge: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: headlineColor,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: headlineColor,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: bodyTextColor,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: bodyMediumColor,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: bodyTextColor,
        ),
      ),
    );
  }
}
