import 'album.dart';
import 'figurinha.dart';

/// Tudo que a tela de figurinhas precisa: o álbum, os números do progresso e a grade.
/// Espelha o `FigurinhasAlbumDto` da API.
class ResumoFigurinhas {
  ResumoFigurinhas({required this.album, required this.figurinhas}) {
    unicas = figurinhas.where((f) => f.quantidade > 0).length;
  }

  final Album album;
  final List<Figurinha> figurinhas;
  late final int unicas;

  int get total => album.total;
  int get faltantes => total - unicas;

  /// Regra do site: round(unicas / total * 100).
  int get progresso => total == 0 ? 0 : (unicas / total * 100).round();
}
