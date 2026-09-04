import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFFFFCE02);
  static const Color onPrimary = Color(0xFF1A1A1A);
  static const Color danger = Color(0xFFE0433C);
  static const Color success = Color(0xFF2FA84F);
}

/// Surface/text colors that flip between light and dark themes.
/// Access via `context.colors` rather than the theme directly.
class AppColorTokens extends ThemeExtension<AppColorTokens> {
  const AppColorTokens({
    required this.text,
    required this.textMuted,
    required this.border,
    required this.card,
    required this.cardAlt,
    required this.shadowSoft,
    required this.shadowStrong,
  });

  final Color text;
  final Color textMuted;
  final Color border;
  final Color card;
  final Color cardAlt;
  final Color shadowSoft;
  final Color shadowStrong;

  static const light = AppColorTokens(
    text: Color(0xFF1A1A1A),
    textMuted: Color(0xFF8A8A8A),
    border: Color(0xFFE3E3E3),
    card: Colors.white,
    cardAlt: Color(0xFFF5F5F5),
    shadowSoft: Color(0x0F000000),
    shadowStrong: Color(0x1F000000),
  );

  static const dark = AppColorTokens(
    text: Color(0xFFF2F2F2),
    textMuted: Color(0xFFA0A0A0),
    border: Color(0xFF3A3A3A),
    card: Color(0xFF1E1E1E),
    cardAlt: Color(0xFF2A2A2A),
    shadowSoft: Color(0x4D000000),
    shadowStrong: Color(0x66000000),
  );

  @override
  AppColorTokens copyWith({
    Color? text,
    Color? textMuted,
    Color? border,
    Color? card,
    Color? cardAlt,
    Color? shadowSoft,
    Color? shadowStrong,
  }) {
    return AppColorTokens(
      text: text ?? this.text,
      textMuted: textMuted ?? this.textMuted,
      border: border ?? this.border,
      card: card ?? this.card,
      cardAlt: cardAlt ?? this.cardAlt,
      shadowSoft: shadowSoft ?? this.shadowSoft,
      shadowStrong: shadowStrong ?? this.shadowStrong,
    );
  }

  @override
  AppColorTokens lerp(ThemeExtension<AppColorTokens>? other, double t) {
    if (other is! AppColorTokens) return this;
    return AppColorTokens(
      text: Color.lerp(text, other.text, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
      card: Color.lerp(card, other.card, t)!,
      cardAlt: Color.lerp(cardAlt, other.cardAlt, t)!,
      shadowSoft: Color.lerp(shadowSoft, other.shadowSoft, t)!,
      shadowStrong: Color.lerp(shadowStrong, other.shadowStrong, t)!,
    );
  }
}

extension AppColorsContext on BuildContext {
  AppColorTokens get colors => Theme.of(this).extension<AppColorTokens>()!;
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(Brightness.light, AppColorTokens.light);

  static ThemeData get dark => _build(Brightness.dark, AppColorTokens.dark);

  static ThemeData _build(Brightness brightness, AppColorTokens tokens) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: brightness == Brightness.light
          ? Colors.white
          : const Color(0xFF121212),
      fontFamily: 'Roboto',
      extensions: [tokens],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: tokens.text,
        centerTitle: false,
      ),
      textTheme: TextTheme(
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: tokens.text,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: tokens.text,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: tokens.text,
        ),
        bodyMedium: TextStyle(fontSize: 14, color: tokens.text),
        bodySmall: TextStyle(fontSize: 12, color: tokens.textMuted),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.cardAlt,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          minimumSize: const Size.fromHeight(52),
          elevation: 0,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          shape: const StadiumBorder(),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: tokens.text,
          side: BorderSide(color: tokens.border),
          minimumSize: const Size.fromHeight(48),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          shape: const StadiumBorder(),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: tokens.text,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          shape: const StadiumBorder(),
        ),
      ),
      dividerTheme: DividerThemeData(color: tokens.border, thickness: 1),
    );
  }
}
