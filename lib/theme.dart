import 'package:flutter/material.dart';
import 'theme_constants.dart';

final ThemeData lightTheme = ThemeData(

  brightness: Brightness.light,
  primaryColor: AppColors.primary,
  scaffoldBackgroundColor: AppColors.background,
  cardColor: AppColors.lightCard,
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.appBar,
    foregroundColor: AppColors.onAppBar,
    titleTextStyle: const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 20,
    ),
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: AppColors.text, fontSize: 14),
    bodyMedium: TextStyle(color: AppColors.text, fontSize: 13),
    bodySmall: TextStyle(color: AppColors.text, fontSize: 11),
    headlineLarge: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold, fontSize: 20),
    headlineMedium: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold, fontSize: 17),
    headlineSmall: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold, fontSize: 15),
    titleMedium: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold, fontSize: 14),
  ),
  colorScheme: ColorScheme.light(
    primary: AppColors.primary,
    secondary: AppColors.accent,
    background: AppColors.background,
    surface: AppColors.lightCard,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onBackground: AppColors.text,
    onSurface: AppColors.text,
  ),
  useMaterial3: true,
);

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: AppColors.primary,
  scaffoldBackgroundColor: AppColors.darkBackground,
  cardColor: AppColors.darkCard,
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.darkBackground,
    foregroundColor: Colors.white,
    titleTextStyle: const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 20,
    ),
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: AppColors.darkText, fontSize: 14),
    bodyMedium: TextStyle(color: AppColors.darkText, fontSize: 13),
    bodySmall: TextStyle(color: AppColors.darkText, fontSize: 11),
    headlineLarge: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.bold, fontSize: 20),
    headlineMedium: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.bold, fontSize: 17),
    headlineSmall: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.bold, fontSize: 15),
    titleMedium: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.bold, fontSize: 14),
  ),
  colorScheme: ColorScheme.dark(
    primary: AppColors.primary,
    secondary: AppColors.accent,
    background: AppColors.darkBackground,
    surface: AppColors.darkCard,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onBackground: AppColors.darkText,
    onSurface: AppColors.darkText,
  ),
  useMaterial3: true,
); 