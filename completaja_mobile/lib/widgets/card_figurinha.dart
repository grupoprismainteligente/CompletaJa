import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/figurinha.dart';

/// Uma figurinha da grade. Três estados visuais, como no site:
/// faltante (tracejada/apagada, "+"), colada (verde, check) e repetida (dourada, "+N").
/// Tocar abre o editor de quantidade e nome.
class CardFigurinha extends StatelessWidget {
  const CardFigurinha({super.key, required this.figurinha, required this.aoSalvar});

  final Figurinha figurinha;

  /// Chamado ao salvar no editor; quem usa o card é quem grava na API.
  final Future<void> Function(int quantidade, String nome) aoSalvar;

  @override
  Widget build(BuildContext context) {
    final f = figurinha;
    final colada = !f.faltante;

    // Stack sobrepõe widgets; o selo fica "pendurado" no canto, fora do card,
    // por isso clipBehavior: Clip.none (senão o Flutter corta o que passa da borda).
    return GestureDetector(
      onTap: () => _mostrarEditor(context),
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

  // Janela de edição, no mesmo desenho do modal do site: quantidade em mãos e nome.
  // Ao salvar, fecha e entrega os valores para a tela, que grava na API.
  Future<void> _mostrarEditor(BuildContext context) async {
    final resultado = await showDialog<({int quantidade, String nome})>(
      context: context,
      builder: (_) => _EditorFigurinha(figurinha: figurinha),
    );
    if (resultado != null) await aoSalvar(resultado.quantidade, resultado.nome);
  }
}

class _EditorFigurinha extends StatefulWidget {
  const _EditorFigurinha({required this.figurinha});

  final Figurinha figurinha;

  @override
  State<_EditorFigurinha> createState() => _EditorFigurinhaState();
}

class _EditorFigurinhaState extends State<_EditorFigurinha> {
  // Mesmo limite da API (QuantidadeMaxima) e do tamanho da coluna Nome.
  static const _quantidadeMaxima = 99;
  static const _nomeMaximo = 100;

  late int _quantidade = widget.figurinha.quantidade;
  late final TextEditingController _nome = TextEditingController(text: widget.figurinha.nome);

  @override
  void dispose() {
    _nome.dispose();
    super.dispose();
  }

  void _mudar(int delta) => setState(() => _quantidade = (_quantidade + delta).clamp(0, _quantidadeMaxima));

  @override
  Widget build(BuildContext context) {
    return Dialog(
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
                    children: [TextSpan(text: widget.figurinha.codigo, style: AppTextos.modalNumero)],
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.pop(context),
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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: _quantidade > 0 ? () => _mudar(-1) : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        color: AppCores.primaria,
                      ),
                      SizedBox(
                        width: 56,
                        child: Text('$_quantidade', style: AppTextos.modalQuantidade, textAlign: TextAlign.center),
                      ),
                      IconButton(
                        onPressed: _quantidade < _quantidadeMaxima ? () => _mudar(1) : null,
                        icon: const Icon(Icons.add_circle_outline),
                        color: AppCores.primaria,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppEspacos.lateral),
            Text('Nome do Jogador / Item', style: AppTextos.modalRotulo),
            const SizedBox(height: AppEspacos.minimo + 1),
            TextField(
              controller: _nome,
              maxLength: _nomeMaximo,
              style: AppTextos.modalValor,
              decoration: const InputDecoration(hintText: 'Sem nome', counterText: ''),
            ),
            const SizedBox(height: AppEspacos.lateral),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, (quantidade: _quantidade, nome: _nome.text.trim())),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppCores.primaria,
                  foregroundColor: AppCores.superficie,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: AppEspacos.compacto),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRaios.medio)),
                ),
                child: Text('Salvar', style: AppTextos.botaoPrimario),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
