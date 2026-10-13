import 'package:flutter/material.dart';

import '../widgets/mensagem_central.dart';

/// Tela das abas que ficaram para a V2 (Locais e Trocas).
class EmBreveScreen extends StatelessWidget {
  const EmBreveScreen({
    super.key,
    required this.titulo,
    required this.icone,
    required this.descricao,
  });

  final String titulo;
  final IconData icone;
  final String descricao;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: MensagemCentral(icone: icone, titulo: 'Em breve', texto: descricao),
    );
  }
}
