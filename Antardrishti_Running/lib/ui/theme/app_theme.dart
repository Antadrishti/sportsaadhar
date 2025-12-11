import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// SportsAadhaar Theme Configuration
/// Enhanced Material 3 theme with custom colors and typography
class AppTheme {
  AppTheme._();

  // ============== LIGHT THEME ==============
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryOrange,
        onPrimary: AppColors.white,
        primaryContainer: AppColors.orange100,
        onPrimaryContainer: AppColors.orange900,
        secondary: AppColors.secondaryPurple,
        onSecondary: AppColors.white,
        secondaryContainer: AppColors.purple100,
        onSecondaryContainer: AppColors.purple900,
        tertiary: AppColors.gold,
        onTertiary: AppColors.black,
        tertiaryContainer: Color(0xFFFFF8E1),
        onTertiaryContainer: Color(0xFF5D4200),
        error: AppColors.error,
        onError: AppColors.white,
        errorContainer: AppColors.errorBg,
        onErrorContainer: AppColors.errorDark,
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightTextPrimary,
        surfaceContainerHighest: AppColors.lightSurfaceVariant,
        onSurfaceVariant: AppColors.lightTextSecondary,
        outline: AppColors.lightBorder,
        outlineVariant: AppColors.gray200,
        shadow: AppColors.black,
        scrim: AppColors.black,
        inverseSurface: AppColors.gray900,
        onInverseSurface: AppColors.gray100,
        inversePrimary: AppColors.primaryOrangeLight,
      ),
      
      // Scaffold
      scaffoldBackgroundColor: AppColors.lightBackground,
      
      // Typography
      textTheme: AppTypography.lightTextTheme,
      
      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightSurface,
        foregroundColor: AppColors.secondaryPurple,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: AppTypography.titleMedium.copyWith(
          color: AppColors.secondaryPurple,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.secondaryPurple,
          size: 24,
        ),
      ),
      
      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryOrange,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.gray300,
          disabledForegroundColor: AppColors.gray500,
          elevation: 0,
          shadowColor: AppColors.primaryOrange.withOpacity(0.3),
          minimumSize: const Size.fromHeight(56),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: AppTypography.button,
        ),
      ),
      
      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryOrange,
          disabledForegroundColor: AppColors.gray400,
          side: const BorderSide(color: AppColors.primaryOrange, width: 1.5),
          minimumSize: const Size.fromHeight(56),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: AppTypography.button,
        ),
      ),
      
      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryOrange,
          disabledForegroundColor: AppColors.gray400,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: AppTypography.labelLarge,
        ),
      ),
      
      // Icon Button
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.secondaryPurple,
          disabledForegroundColor: AppColors.gray400,
          padding: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      
      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryOrange,
        foregroundColor: AppColors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      // Card
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: AppColors.black.withOpacity(0.08),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: AppColors.lightBorder.withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      
      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primaryOrange, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.gray200),
        ),
        labelStyle: AppTypography.bodyMedium.copyWith(color: AppColors.lightTextSecondary),
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.lightTextTertiary),
        errorStyle: AppTypography.bodySmall.copyWith(color: AppColors.error),
        prefixIconColor: AppColors.lightTextSecondary,
        suffixIconColor: AppColors.lightTextSecondary,
      ),
      
      // Bottom Navigation Bar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        selectedItemColor: AppColors.primaryOrange,
        unselectedItemColor: AppColors.gray400,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
      
      // Navigation Bar (Material 3)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        indicatorColor: AppColors.orange100,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 70,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primaryOrange, size: 26);
          }
          return const IconThemeData(color: AppColors.gray400, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.labelSmall.copyWith(
              color: AppColors.primaryOrange,
              fontWeight: FontWeight.w600,
            );
          }
          return AppTypography.labelSmall.copyWith(color: AppColors.gray500);
        }),
      ),
      
      // Tab Bar
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.primaryOrange,
        unselectedLabelColor: AppColors.gray500,
        indicatorColor: AppColors.primaryOrange,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
      ),
      
      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightSurfaceVariant,
        selectedColor: AppColors.orange100,
        disabledColor: AppColors.gray200,
        labelStyle: AppTypography.labelMedium,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        side: BorderSide.none,
      ),
      
      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.lightSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titleTextStyle: AppTypography.titleLarge.copyWith(color: AppColors.lightTextPrimary),
        contentTextStyle: AppTypography.bodyMedium.copyWith(color: AppColors.lightTextSecondary),
      ),
      
      // Bottom Sheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.lightSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        modalElevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      
      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.gray900,
        contentTextStyle: AppTypography.bodyMedium.copyWith(color: AppColors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),
      
      // Progress Indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primaryOrange,
        linearTrackColor: AppColors.orange100,
        circularTrackColor: AppColors.orange100,
      ),
      
      // Slider
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.primaryOrange,
        inactiveTrackColor: AppColors.orange100,
        thumbColor: AppColors.primaryOrange,
        overlayColor: AppColors.primaryOrange.withOpacity(0.2),
        valueIndicatorColor: AppColors.secondaryPurple,
        valueIndicatorTextStyle: AppTypography.labelMedium.copyWith(color: AppColors.white),
      ),
      
      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.white;
          }
          return AppColors.gray400;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryOrange;
          }
          return AppColors.gray300;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      
      // Checkbox
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryOrange;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(AppColors.white),
        side: const BorderSide(color: AppColors.gray400, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      
      // Radio
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryOrange;
          }
          return AppColors.gray400;
        }),
      ),
      
      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.lightBorder,
        thickness: 1,
        space: 1,
      ),
      
      // List Tile
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        titleTextStyle: AppTypography.titleSmall.copyWith(color: AppColors.lightTextPrimary),
        subtitleTextStyle: AppTypography.bodySmall.copyWith(color: AppColors.lightTextSecondary),
        leadingAndTrailingTextStyle: AppTypography.labelMedium.copyWith(color: AppColors.lightTextSecondary),
      ),
      
      // Expansion Tile
      expansionTileTheme: ExpansionTileThemeData(
        backgroundColor: AppColors.lightSurface,
        collapsedBackgroundColor: AppColors.lightSurface,
        textColor: AppColors.primaryOrange,
        collapsedTextColor: AppColors.lightTextPrimary,
        iconColor: AppColors.primaryOrange,
        collapsedIconColor: AppColors.gray500,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      
      // Tooltip
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.gray900,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: AppTypography.bodySmall.copyWith(color: AppColors.white),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  // ============== DARK THEME ==============
  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // Color Scheme
      colorScheme: ColorScheme.dark(
        primary: AppColors.primaryOrange,
        onPrimary: AppColors.white,
        primaryContainer: AppColors.orange800,
        onPrimaryContainer: AppColors.orange100,
        secondary: AppColors.secondaryPurpleLight,
        onSecondary: AppColors.white,
        secondaryContainer: AppColors.purple800,
        onSecondaryContainer: AppColors.purple100,
        tertiary: AppColors.goldLight,
        onTertiary: AppColors.black,
        tertiaryContainer: const Color(0xFF5D4200),
        onTertiaryContainer: const Color(0xFFFFF8E1),
        error: AppColors.errorLight,
        onError: AppColors.black,
        errorContainer: AppColors.errorDark,
        onErrorContainer: AppColors.errorBg,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkTextPrimary,
        surfaceContainerHighest: AppColors.darkSurfaceVariant,
        onSurfaceVariant: AppColors.darkTextSecondary,
        outline: AppColors.darkBorder,
        outlineVariant: AppColors.gray700,
        shadow: AppColors.black,
        scrim: AppColors.black,
        inverseSurface: AppColors.gray100,
        onInverseSurface: AppColors.gray900,
        inversePrimary: AppColors.primaryOrangeDark,
      ),
      
      // Scaffold
      scaffoldBackgroundColor: AppColors.darkBackground,
      
      // Typography
      textTheme: AppTypography.darkTextTheme,
      
      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: AppTypography.titleMedium.copyWith(
          color: AppColors.darkTextPrimary,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.darkTextPrimary,
          size: 24,
        ),
      ),
      
      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryOrange,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.gray700,
          disabledForegroundColor: AppColors.gray500,
          elevation: 0,
          shadowColor: AppColors.primaryOrange.withOpacity(0.3),
          minimumSize: const Size.fromHeight(56),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: AppTypography.button,
        ),
      ),
      
      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryOrange,
          disabledForegroundColor: AppColors.gray600,
          side: const BorderSide(color: AppColors.primaryOrange, width: 1.5),
          minimumSize: const Size.fromHeight(56),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: AppTypography.button,
        ),
      ),
      
      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryOrange,
          disabledForegroundColor: AppColors.gray600,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: AppTypography.labelLarge,
        ),
      ),
      
      // Card
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: AppColors.black.withOpacity(0.4),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: AppColors.darkBorder.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      
      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primaryOrange, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle: AppTypography.bodyMedium.copyWith(color: AppColors.darkTextSecondary),
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.darkTextTertiary),
        errorStyle: AppTypography.bodySmall.copyWith(color: AppColors.errorLight),
        prefixIconColor: AppColors.darkTextSecondary,
        suffixIconColor: AppColors.darkTextSecondary,
      ),
      
      // Bottom Navigation Bar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.primaryOrange,
        unselectedItemColor: AppColors.gray500,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
      
      // Navigation Bar (Material 3)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        indicatorColor: AppColors.orange800.withOpacity(0.5),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 70,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primaryOrange, size: 26);
          }
          return const IconThemeData(color: AppColors.gray500, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.labelSmall.copyWith(
              color: AppColors.primaryOrange,
              fontWeight: FontWeight.w600,
            );
          }
          return AppTypography.labelSmall.copyWith(color: AppColors.gray500);
        }),
      ),
      
      // Tab Bar
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.primaryOrange,
        unselectedLabelColor: AppColors.gray500,
        indicatorColor: AppColors.primaryOrange,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
      ),
      
      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titleTextStyle: AppTypography.titleLarge.copyWith(color: AppColors.darkTextPrimary),
        contentTextStyle: AppTypography.bodyMedium.copyWith(color: AppColors.darkTextSecondary),
      ),
      
      // Bottom Sheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        modalElevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      
      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.gray100,
        contentTextStyle: AppTypography.bodyMedium.copyWith(color: AppColors.gray900),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),
      
      // Progress Indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primaryOrange,
        linearTrackColor: AppColors.orange800,
        circularTrackColor: AppColors.orange800,
      ),
      
      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
