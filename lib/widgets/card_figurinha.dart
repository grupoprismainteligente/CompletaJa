import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/figurinha.dart';

/// Uma figurinha da grade. Três estados visuais, como no site:
/// faltante (tracejada/apagada, "+"), colada (verde, check) e repetida (dourada, "+N").
class CardFigurinha extends StatelessWidget {
  const CardFigurinha({super.key, required this.figurinha});

  final Figurinha figurinha;

  @override
  Widget build(BuildContext context) {
    final f = figurinha;
    final colada = !f.faltante;

    // Stack sobrepõe widgets; o selo fica "pendurado" no canto, fora do card,
    // por isso clipBehavior: Clip.none (senão o Flutter corta o que passa da borda).
    return GestureDetector(
      onTap: () => _mostrarDetalhe(context),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: f.faltante ? 0.8 : 1,
              child: Container(
                padding: const EdgeInsets.all(AppEspacos.campo),
                decoration: BoxDecoration(
                  color: colada ? AppCores.coladaFundo : AppCores.fundoPagina,
                  borderRadius: BorderRadius.circular(AppRaios.medio),
                  border: Border.all(
                    color: colada ? AppCores.colada : AppCores.trilhaProgresso,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Expanded(child: Center(child: _icone())),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(top: AppEspacos.minimo + 1),
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: AppCores.bordaSuave)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            f.codigo,
                            style: colada ? AppTextos.figNumeroColada : AppTextos.figNumero,
                          ),
                          Text(
                            (f.nome.isEmpty ? 'Adicionar' : f.nome).toUpperCase(),
                            style: AppTextos.figNome,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (colada)
            Positioned(
              top: -AppEspacos.pequeno,
              right: -AppEspacos.pequeno,
              child: _selo(),
            ),
        ],
      ),
    );
  }

  Widget _icone() {
    if (figurinha.faltante) {
      return const Icon(Icons.add_circle, size: 35, color: AppCores.faltante);
    }
    if (figurinha.repetida) {
      return const Icon(Icons.layers, size: 40, color: AppCores.repetida);
    }
    return const Icon(Icons.check_circle, size: 40, color: AppCores.colada);
  }

  Widget _selo() {
    final repetida = figurinha.repetida;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppEspacos.pequeno, vertical: AppEspacos.minimo),
      decoration: BoxDecoration(
        color: repetida ? AppCores.repetida : AppCores.colada,
        borderRadius: BorderRadius.circular(AppRaios.medio),
        border: Border.all(color: AppCores.superficie, width: 2),
      ),
      child: Text(
        repetida ? '+${figurinha.extras}' : '1',
        style: repetida ? AppTextos.figBadgeExtra : AppTextos.figBadge,
      ),
    );
  }

  // Janela de detalhe, no mesmo desenho do modal do site, porém só leitura
  // (esta versão do app é apenas de consulta).
  void _mostrarDetalhe(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(AppEspacos.lateral + 5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text.rich(
                    TextSpan(
                      text: 'Figurinha ',
                      style: AppTextos.modalTitulo,
                      children: [TextSpan(text: figurinha.codigo, style: AppTextos.modalNumero)],
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(ctx),
                    child: const Icon(Icons.close, color: AppCores.textoSuave),
                  ),
                ],
              ),
              const SizedBox(height: AppEspacos.lateral),
              Center(
                child: Column(
                  children: [
                    Text('Quantidade em Mãos', style: AppTextos.modalRotulo),
                    const SizedBox(height: AppEspacos.compacto),
                    Text('${figurinha.quantidade}', style: AppTextos.modalQuantidade),
                  ],
                ),
              ),
              const SizedBox(height: AppEspacos.lateral),
              Text('Nome do Jogador / Item', style: AppTextos.modalRotulo),
              const SizedBox(height: AppEspacos.minimo + 1),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppEspacos.compacto),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRaios.campo),
                  border: Border.all(color: AppCores.borda),
                ),
                child: Text(
                  figurinha.nome.isEmpty ? 'Sem nome' : figurinha.nome,
                  style: AppTextos.modalValor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
