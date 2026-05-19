import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'logic/providers/translation_provider.dart';
import 'logic/providers/theme_provider.dart';
import 'presentation/screens/home_screen.dart';

void main() {
  runApp(
    // Wrap application in MultiProvider to initialize our states (Theme + Translation)
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => TranslationProvider()),
      ],
      child: const XJTranslatorApp(),
    ),
  );
}

class XJTranslatorApp extends StatelessWidget {
  const XJTranslatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch ThemeProvider for changes (rebuilds when theme mode or primary color changes)
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'Soon',
      debugShowCheckedModeBanner: false,
      
      // Wire up custom dynamic Light & Dark themes
      theme: AppTheme.lightTheme(themeProvider.primaryColor),
      darkTheme: AppTheme.darkTheme(themeProvider.primaryColor),
      themeMode: themeProvider.themeMode,

      home: const HomeScreen(),
    );
  }
}
