import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_typography.dart';
import 'nc_theme.dart';

/// Tema Material construido sobre el design system móvil "Carnaval".
///
/// - Botones en píldora de 48 px; primario azul neón con brillo en oscuro.
/// - Tarjetas radio 22, bordes de 1 px translúcidos.
/// - Barras superior e inferior sobre el color de fondo, con borde sutil.
/// - Snackbar tipo "toast" en píldora.
class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(NcColors.light);
  static ThemeData get dark => _build(NcColors.dark);

  static ThemeData _build(NcColors nc) {
    final brightness = nc.isDark ? Brightness.dark : Brightness.light;
    final base = nc.isDark ? ThemeData.dark() : ThemeData.light();

    final scheme = ColorScheme(
      brightness: brightness,
      primary: nc.azul,
      onPrimary: nc.onAzul,
      secondary: nc.naranja,
      onSecondary: Colors.white,
      tertiary: nc.magenta,
      onTertiary: Colors.white,
      error: AppColors.tomate,
      onError: Colors.white,
      surface: nc.bgCard,
      onSurface: nc.textPrimary,
      onSurfaceVariant: nc.textSecondary,
      surfaceContainerHighest: nc.bgSubtle,
      outline: nc.border,
      outlineVariant: nc.border,
    );

    const pill = StadiumBorder();
    const buttonPadding = EdgeInsets.symmetric(horizontal: 24, vertical: 12);
    const buttonMinSize = Size(64, 48);

    OutlineInputBorder inputBorder(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c, width: w),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: nc.bg,
      canvasColor: nc.bg,
      dividerColor: nc.border,
      splashFactory: InkSparkle.splashFactory,
      extensions: [nc],
      textTheme: GoogleFonts.interTextTheme(base.textTheme)
          .apply(bodyColor: nc.textPrimary, displayColor: nc.textPrimary)
          .copyWith(
            displayLarge: AppTypography.displayBlack(color: nc.textPrimary),
            displayMedium: AppTypography.displayBold(color: nc.textPrimary),
            displaySmall: AppTypography.displaySemiBold(color: nc.textPrimary),
            titleLarge: AppTypography.displaySemiBold(color: nc.textPrimary),
            titleMedium: AppTypography.labelSemiBold(color: nc.textPrimary),
            bodyLarge: AppTypography.bodyLarge(color: nc.textPrimary),
            bodyMedium: AppTypography.bodyMedium(color: nc.textPrimary),
            bodySmall: AppTypography.bodySmall(color: nc.textSecondary),
            labelLarge: AppTypography.buttonText(),
            labelMedium: AppTypography.labelMedium(color: nc.textSecondary),
            labelSmall: AppTypography.caption(color: nc.textSecondary),
          ),
      appBarTheme: AppBarTheme(
        backgroundColor: nc.bg,
        foregroundColor: nc.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.displaySemiBold(color: nc.textPrimary)
            .copyWith(fontSize: 18),
        iconTheme: IconThemeData(color: nc.textPrimary),
        actionsIconTheme: IconThemeData(color: nc.textPrimary),
        shape: Border(bottom: BorderSide(color: nc.border)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: nc.azul,
          foregroundColor: nc.onAzul,
          disabledBackgroundColor: nc.bgSubtle,
          disabledForegroundColor: nc.textMuted,
          textStyle: AppTypography.buttonText(),
          shape: pill,
          minimumSize: buttonMinSize,
          padding: buttonPadding,
          // Brillo neón suave (≈ box-shadow 0 0 20px rgba(0,229,255,.3)).
          elevation: nc.isDark ? 10 : 0,
          shadowColor: AppColors.azulNeon.withValues(alpha: 0.28),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: nc.azul,
          foregroundColor: nc.onAzul,
          textStyle: AppTypography.buttonText(),
          shape: pill,
          minimumSize: buttonMinSize,
          padding: buttonPadding,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: nc.secondaryFill,
          foregroundColor: nc.textPrimary,
          side: BorderSide(color: nc.border),
          textStyle: AppTypography.buttonText().copyWith(
            fontWeight: FontWeight.w500,
          ),
          shape: pill,
          minimumSize: buttonMinSize,
          padding: buttonPadding,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: nc.azul,
          textStyle: AppTypography.buttonText().copyWith(fontSize: 14),
          minimumSize: const Size(44, 44),
          shape: pill,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: nc.textPrimary,
          minimumSize: const Size(44, 44),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: nc.azul,
        foregroundColor: nc.onAzul,
        elevation: nc.isDark ? 8 : 2,
        shape: pill,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: nc.bgCard,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: inputBorder(nc.border),
        enabledBorder: inputBorder(
            nc.isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black12),
        focusedBorder: inputBorder(nc.azul, 1.5),
        errorBorder: inputBorder(AppColors.tomate),
        focusedErrorBorder: inputBorder(AppColors.tomate, 1.5),
        labelStyle: AppTypography.bodyMedium(color: nc.textSecondary),
        floatingLabelStyle: AppTypography.bodyMedium(color: nc.azul),
        hintStyle: AppTypography.bodyMedium(color: nc.textMuted),
        prefixIconColor: nc.textSecondary,
        suffixIconColor: nc.textSecondary,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: nc.secondaryFill,
        selectedColor: nc.azul.withValues(alpha: 0.16),
        labelStyle: AppTypography.labelMedium(color: nc.textPrimary),
        secondaryLabelStyle: AppTypography.labelMedium(color: nc.azul),
        shape: pill,
        side: BorderSide(color: nc.border),
        checkmarkColor: nc.azul,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      cardTheme: CardThemeData(
        color: nc.bgCard,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: nc.border),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: nc.textSecondary,
        textColor: nc.textPrimary,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: DividerThemeData(color: nc.border, thickness: 1, space: 1),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: nc.bgGlass,
        selectedItemColor: nc.azul,
        unselectedItemColor: nc.textSecondary,
        selectedLabelStyle: AppTypography.caption(),
        unselectedLabelStyle: AppTypography.caption(),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: nc.bgGlass,
        indicatorColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith((s) =>
            AppTypography.caption(
                color: s.contains(WidgetState.selected)
                    ? nc.azul
                    : nc.textSecondary)),
        iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
            size: 22,
            color: s.contains(WidgetState.selected)
                ? nc.azul
                : nc.textSecondary)),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: nc.azul,
        unselectedLabelColor: nc.textSecondary,
        indicatorColor: nc.azul,
        dividerColor: nc.border,
        labelStyle: AppTypography.labelSemiBold().copyWith(fontSize: 14),
        unselectedLabelStyle:
            AppTypography.labelMedium().copyWith(fontSize: 14),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: nc.textPrimary,
        contentTextStyle: AppTypography.labelSemiBold(color: nc.bg)
            .copyWith(fontSize: 14),
        actionTextColor: nc.azul,
        shape: pill,
        elevation: 0,
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: nc.bgCard,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: nc.bgCard,
        showDragHandle: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: nc.bgCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        titleTextStyle: AppTypography.displaySemiBold(color: nc.textPrimary),
        contentTextStyle: AppTypography.bodyMedium(color: nc.textSecondary),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: nc.bgCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: nc.azul,
        linearTrackColor: nc.border,
        circularTrackColor: Colors.transparent,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? nc.onAzul : nc.textSecondary),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? nc.azul : nc.bgSubtle),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? nc.azul : Colors.transparent),
        checkColor: WidgetStateProperty.all(nc.onAzul),
        side: BorderSide(color: nc.textSecondary, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? nc.azul : nc.textSecondary),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: nc.azul,
        thumbColor: nc.azul,
        inactiveTrackColor: nc.border,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: nc.bgCard,
        surfaceTintColor: Colors.transparent,
        todayForegroundColor: WidgetStateProperty.all(nc.azul),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
    );
  }
}
