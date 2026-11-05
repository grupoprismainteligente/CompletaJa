import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../models/album.dart';
import '../core/api_client.dart';
import '../services/album_service.dart';
import '../widgets/aviso.dart';
import '../widgets/campo_busca.dart';
import '../widgets/card_album.dart';
import '../widgets/carrega_dados.dart';
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
    if (confirmou != true || !mounted) return;

    final servico = context.read<AlbumService>();
    try {
      await servico.vincular(album.id);
    } on ApiException catch (e) {
      if (mounted) mostrarAviso(context, e.mensagem);
      return;
    }
    // Como no site, depois de vincular volta para Meus Álbuns (a tela anterior).
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return TelaPadrao(
      aba: Aba.albuns,
      corpo: CarregaDados<List<Album>>(
        carregar: context.read<AlbumService>().catalogo,
        construir: (context, catalogo) {
          final albuns = catalogo
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
                  jaColeciona: album.jaColeciona,
                  // null desativa o toque quando o usuário já coleciona.
                  aoTocar: album.jaColeciona ? null : () => _confirmar(album),
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
