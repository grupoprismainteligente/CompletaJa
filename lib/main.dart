import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'screens/login_screen.dart';

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
      // Com dados fictícios o app sempre abre no login. Quando o login real
      // existir, esta tela passa a decidir entre login e Home (se há token salvo).
      home: const LoginScreen(),
    );
  }
}
