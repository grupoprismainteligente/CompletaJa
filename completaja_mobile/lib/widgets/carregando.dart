import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Tela cheia de "carregando", usada enquanto o app decide se há sessão salva.
class TelaCarregando extends StatelessWidget {
  const TelaCarregando({super.key, this.mensagem});

  final String? mensagem;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCores.fundoPagina,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppCores.primaria),
            if (mensagem != null) ...[
              const SizedBox(height: AppEspacos.medio),
              Text(mensagem!, textAlign: TextAlign.center, style: AppTextos.emBreveTexto),
            ],
          ],
        ),
      ),
    );
  }
}
