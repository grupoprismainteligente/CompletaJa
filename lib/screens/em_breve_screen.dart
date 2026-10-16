import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../widgets/tela_padrao.dart';

/// Tela das abas que ficaram para a V2 (Locais e Trocas).
class EmBreveScreen extends StatelessWidget {
  const EmBreveScreen({
    super.key,
    required this.aba,
    required this.titulo,
    required this.icone,
    required this.descricao,
  });

  final Aba aba;
  final String titulo;
  final IconData icone;
  final String descricao;

  @override
  Widget build(BuildContext context) {
    return TelaPadrao(
      aba: aba,
      corpo: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppEspacos.grande),
          child: Column(
            // min: a coluna ocupa só a altura do conteúdo, e o Center consegue centralizá-la.
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icone, size: AppTamanhos.iconeDestaque, color: AppCores.primaria),
              const SizedBox(height: AppEspacos.medio),
              Text('$titulo: em breve', style: AppTextos.emBreveTitulo, textAlign: TextAlign.center),
              const SizedBox(height: AppEspacos.pequeno),
              Text(descricao, style: AppTextos.emBreveTexto, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
