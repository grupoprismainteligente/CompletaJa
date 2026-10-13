import 'package:flutter/material.dart';

import '../widgets/mensagem_central.dart';

/// Início. PROVISÓRIA: os contadores de repetidas e faltantes entram na etapa 6.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Início')),
      body: const MensagemCentral(
        icone: Icons.home_outlined,
        titulo: 'Bem-vindo ao CompletaJá',
        texto: 'Aqui vão aparecer suas repetidas e faltantes.',
      ),
    );
  }
}
