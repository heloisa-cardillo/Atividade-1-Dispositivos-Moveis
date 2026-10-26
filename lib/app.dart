import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'features/localizacoes/presentation/screens/tela_coleta.dart';

class App extends StatelessWidget {
  const App({super.key});

  static const Color _azul = Color(0xFF2A49EB);
  static const Color _fundo = Color(0xFFF5F7FA);
  static const Color _texto = Color(0xFF1F2937);

  ThemeData _tema() {
    final cores = ColorScheme.fromSeed(
      seedColor: _azul,
      primary: _azul,
      surface: _fundo,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cores,
      fontFamily: 'PlusJakartaSans',
      scaffoldBackgroundColor: _fundo,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: _texto,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'PlusJakartaSans',
          color: _texto,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _texto,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _azul,
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFE5E7EB)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Localizações',
      debugShowCheckedModeBanner: false,
      theme: _tema(),
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const TelaColeta(),
    );
  }
}
