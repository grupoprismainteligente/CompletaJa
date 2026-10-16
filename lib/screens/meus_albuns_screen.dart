import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../services/dados_ficticios.dart';
import '../widgets/campo_busca.dart';
import '../widgets/card_album.dart';
import '../widgets/tela_padrao.dart';
import 'catalogo_screen.dart';
import 'figurinhas_screen.dart';

/// Meus Álbuns: lista dos álbuns que o usuário coleciona, com filtro por nome.
class MeusAlbunsScreen extends StatefulWidget {
  const MeusAlbunsScreen({super.key});

  @override
  State<MeusAlbunsScreen> createState() => _MeusAlbunsScreenState();
}

class _MeusAlbunsScreenState extends State<MeusAlbunsScreen> {
  String _filtro = '';

  @override
  Widget build(BuildContext context) {
    final dados = DadosFicticios.instancia;

    return TelaPadrao(
      aba: Aba.albuns,
      corpo: ListenableBuilder(
        listenable: dados,
        builder: (context, _) {
          // where: mantém só os álbuns cujo nome contém o texto digitado.
          final albuns = dados.meusAlbuns
              .where((a) => a.nome.toLowerCase().contains(_filtro.toLowerCase().trim()))
              .toList();

          return ListView(
            padding: const EdgeInsets.all(AppEspacos.lateral),
            children: [
              Text('Meus Álbuns', style: AppTextos.paginaTitulo, textAlign: TextAlign.center),
              const SizedBox(height: AppEspacos.minimo),
              Text(
                'Suas coleções ativas de figurinhas',
                style: AppTextos.paginaSubtitulo,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppEspacos.grande),
              _botaoAdicionar(context),
              const SizedBox(height: AppEspacos.grande),
              CampoBusca(
                dica: 'Filtrar meus álbuns...',
                aoMudar: (texto) => setState(() => _filtro = texto),
              ),
              const SizedBox(height: AppEspacos.enorme),
              if (albuns.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppEspacos.grande),
                  child: Text(
                    dados.meusAlbuns.isEmpty
                        ? 'Você ainda não coleciona nenhum álbum.\nToque em "Adicionar Novo Álbum".'
                        : 'Nenhum álbum encontrado.',
                    style: AppTextos.vazioTexto,
                    textAlign: TextAlign.center,
                  ),
                ),
              for (final album in albuns) ...[
                CardAlbum(
                  album: album,
                  aoTocar: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => FigurinhasScreen(albumId: album.id)),
                  ),
                ),
                const SizedBox(height: AppEspacos.medio),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _botaoAdicionar(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CatalogoScreen()),
            ),
            icon: const Icon(Icons.menu_book, size: 18),
            label: Text('Adicionar Novo Álbum', style: AppTextos.botaoPrimario),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppCores.primaria,
              foregroundColor: AppCores.superficie,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: AppEspacos.compacto, horizontal: AppEspacos.lateral),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRaios.medio)),
            ),
          ),
        ),
      ),
    );
  }
}
