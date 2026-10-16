import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/album.dart';
import '../services/dados_ficticios.dart';
import '../widgets/aviso.dart';
import '../widgets/campo_busca.dart';
import '../widgets/card_album.dart';
import '../widgets/tela_padrao.dart';

/// Catálogo de álbuns do sistema, com busca e "adicionar à minha coleção".
class CatalogoScreen extends StatefulWidget {
  const CatalogoScreen({super.key});

  @override
  State<CatalogoScreen> createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends State<CatalogoScreen> {
  String _filtro = '';

  // Mesma pergunta do site (confirm) antes de vincular o álbum.
  Future<void> _confirmar(Album album) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text('Deseja adicionar o álbum "${album.nome}" às suas coleções ativas?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('OK')),
        ],
      ),
    );
    if (confirmou == true && mounted) {
      DadosFicticios.instancia.vincular(album.id);
      // Como no site, depois de vincular volta para Meus Álbuns (a tela anterior).
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dados = DadosFicticios.instancia;

    return TelaPadrao(
      aba: Aba.albuns,
      corpo: ListenableBuilder(
        listenable: dados,
        builder: (context, _) {
          final albuns = dados.catalogo
              .where((a) => a.nome.toLowerCase().contains(_filtro.toLowerCase().trim()))
              .toList();

          return ListView(
            padding: const EdgeInsets.all(AppEspacos.lateral),
            children: [
              const SizedBox(height: AppEspacos.compacto),
              Text(
                'Catálogo de Álbuns do Sistema',
                style: AppTextos.paginaTitulo,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppEspacos.minimo),
              Text(
                'Selecione uma coleção existente para começar a gerenciar',
                style: AppTextos.paginaSubtitulo,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppEspacos.grande),
              CampoBusca(
                dica: 'Buscar álbum no catálogo...',
                aoMudar: (texto) => setState(() => _filtro = texto),
              ),
              const SizedBox(height: AppEspacos.enorme),
              for (final album in albuns) ...[
                CardAlbum(
                  album: album,
                  catalogo: true,
                  jaColeciona: dados.jaColeciona(album.id),
                  // null desativa o toque quando o usuário já coleciona.
                  aoTocar: dados.jaColeciona(album.id) ? null : () => _confirmar(album),
                ),
                const SizedBox(height: AppEspacos.medio),
              ],
              _cardCriarNovo(context),
            ],
          );
        },
      ),
    );
  }

  Widget _cardCriarNovo(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRaios.card),
      onTap: () => mostrarAviso(context, 'O cadastro de novos álbuns fica disponível no site.'),
      child: Container(
        padding: const EdgeInsets.all(AppEspacos.lateral),
        decoration: BoxDecoration(
          color: AppCores.fundoPagina,
          borderRadius: BorderRadius.circular(AppRaios.card),
          // Borda tracejada não existe pronta no Flutter; usamos sólida na mesma cor.
          border: Border.all(color: AppCores.primaria, width: 2),
        ),
        child: Column(
          children: [
            const Icon(Icons.library_add, size: 35, color: AppCores.primaria),
            const SizedBox(height: AppEspacos.pequeno),
            Text('Não encontrou seu álbum?', style: AppTextos.criarNovoTitulo),
            const SizedBox(height: AppEspacos.minimo),
            Text('Cadastrar novo modelo', style: AppTextos.criarNovoTexto),
          ],
        ),
      ),
    );
  }
}
