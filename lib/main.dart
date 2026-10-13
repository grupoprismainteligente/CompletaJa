import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'screens/app_shell.dart';

void main() {
  runApp(const CompletaJaApp());
}

class CompletaJaApp extends StatelessWidget {
  const CompletaJaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CompletaJá',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.claro,
      // Na etapa 3 a tela inicial passa a decidir entre login e AppShell (se já há token salvo).
      home: const AppShell(),
    );
  }
}
