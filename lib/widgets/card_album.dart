import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/album.dart';

/// Card de álbum usado em Meus Álbuns e no Catálogo (a `.local-card` do site).
/// Em "Meus Álbuns" mostra só o total; no catálogo (`catalogo: true`) mostra também
/// quantos colecionadores o álbum tem e o selo "Você já coleciona".
class CardAlbum extends StatelessWidget {
  const CardAlbum({
    super.key,
    required this.album,
    required this.aoTocar,
    this.catalogo = false,
    this.jaColeciona = false,
  });

  final Album album;
  final VoidCallback? aoTocar;
  final bool catalogo;
  final bool jaColeciona;

  @override
  Widget build(BuildContext context) {
    // Opacity deixa o card esmaecido quando o usuário já coleciona o álbum.
    return Opacity(
      opacity: jaColeciona ? 0.6 : 1,
      child: Material(
        color: AppCores.superficie,
        borderRadius: BorderRadius.circular(AppRaios.card),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRaios.card),
          onTap: aoTocar,
          child: Container(
            padding: const EdgeInsets.all(AppEspacos.medio),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRaios.card),
              border: Border.all(color: AppCores.bordaCard),
              boxShadow: AppSombras.card,
            ),
            child: Row(
              children: [
                _capa(),
                const SizedBox(width: AppEspacos.medio),
                Expanded(child: _detalhes()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _capa() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRaios.grande - 2),
      child: Image.asset(
        album.capa,
        width: AppTamanhos.capaLista,
        height: AppTamanhos.capaLista,
        fit: BoxFit.cover,
        // Imagem quebrada vira um quadrado cinza com ícone (regra do projeto).
        errorBuilder: (_, _, _) => Container(
          width: AppTamanhos.capaLista,
          height: AppTamanhos.capaLista,
          color: AppCores.campo,
          child: const Icon(Icons.menu_book, color: AppCores.textoDesabilitado),
        ),
      ),
    );
  }

  Widget _detalhes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(album.nome, style: AppTextos.cardTitulo),
        const SizedBox(height: AppEspacos.minimo),
        if (catalogo) ...[
          Text('${album.total} figurinhas no total', style: AppTextos.cardDetalhe),
          const SizedBox(height: AppEspacos.minimo),
          Text('${album.usuariosVinculados} colecionadores', style: AppTextos.cardDestaque),
          if (jaColeciona) ...[
            const SizedBox(height: AppEspacos.pequeno),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppEspacos.campo - 2, vertical: AppEspacos.minimo),
              decoration: BoxDecoration(
                color: AppCores.sucessoFundo,
                borderRadius: BorderRadius.circular(AppRaios.medio),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, size: 14, color: AppCores.sucessoTexto),
                  const SizedBox(width: AppEspacos.minimo),
                  Text('Você já coleciona', style: AppTextos.badgeJaColeciona),
                ],
              ),
            ),
          ],
        ] else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppEspacos.campo - 2, vertical: AppEspacos.minimo),
            decoration: BoxDecoration(
              color: AppCores.azulBadge,
              borderRadius: BorderRadius.circular(AppRaios.pilula),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.copy, size: 12, color: AppCores.primaria),
                const SizedBox(width: AppEspacos.pequeno - 2),
                Text('${album.total} figurinhas', style: AppTextos.badgeLista),
              ],
            ),
          ),
      ],
    );
  }
}
