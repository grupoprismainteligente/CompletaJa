import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Ícone + título + texto, centralizados na tela.
/// Usado em "Em breve" e, nas próximas etapas, nos estados de vazio e de erro
/// (por isso aceita um botão opcional, ex.: "Tentar de novo").
class MensagemCentral extends StatelessWidget {
  const MensagemCentral({
    super.key,
    required this.icone,
    required this.titulo,
    required this.texto,
    this.acao,
  });

  final IconData icone;
  final String titulo;
  final String texto;

  /// Botão opcional mostrado abaixo do texto.
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppEspacos.grande),
        child: Column(
          // min: a coluna ocupa só a altura do conteúdo, e o Center consegue centralizá-la.
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: AppTamanhos.iconeDestaque, color: tema.colorScheme.primary),
            const SizedBox(height: AppEspacos.medio),
            Text(titulo, style: tema.textTheme.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: AppEspacos.pequeno),
            Text(texto, style: tema.textTheme.bodyMedium, textAlign: TextAlign.center),
            if (acao != null) ...[
              const SizedBox(height: AppEspacos.grande),
              acao!,
            ],
          ],
        ),
      ),
    );
  }
}
