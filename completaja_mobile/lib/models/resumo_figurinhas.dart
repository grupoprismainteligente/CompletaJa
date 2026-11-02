import 'album.dart';
import 'figurinha.dart';

/// Tudo que a tela de figurinhas precisa: o álbum, os números do progresso e a grade.
/// Espelha o `FigurinhasAlbumDto` da API; os números vêm prontos do servidor,
/// assim a regra de cálculo fica só no back-end.
class ResumoFigurinhas {
  const ResumoFigurinhas({
    required this.album,
    required this.total,
    required this.unicas,
    required this.faltantes,
    required this.progresso,
    required this.figurinhas,
  });

  final Album album;
  final int total;
  final int unicas;
  final int faltantes;
  final int progresso;
  final List<Figurinha> figurinhas;

  /// Cópia com uma figurinha trocada e os contadores refeitos (mesma fórmula do servidor:
  /// round(unicas / total * 100)). Usada para atualizar a tela na hora, antes da API responder.
  ResumoFigurinhas comFigurinha(Figurinha nova) {
    final lista = [for (final f in figurinhas) f.codigo == nova.codigo ? nova : f];
    final unicas = lista.where((f) => f.quantidade > 0).length;
    return ResumoFigurinhas(
      album: album,
      total: total,
      unicas: unicas,
      faltantes: total - unicas,
      progresso: total == 0 ? 0 : (unicas / total * 100).round(),
      figurinhas: lista,
    );
  }

  factory ResumoFigurinhas.fromJson(Map<String, dynamic> json) {
    final total = json['total'] as int? ?? 0;
    final resumoAlbum = json['album'] as Map<String, dynamic>;
    return ResumoFigurinhas(
      // O DTO de figurinhas traz só id/nome/capa do álbum; o total vem ao lado.
      album: Album(
        id: resumoAlbum['id'] as int,
        nome: resumoAlbum['nome'] as String? ?? '',
        capaUrl: resumoAlbum['capaUrl'] as String?,
        total: total,
        usuariosVinculados: 0,
      ),
      total: total,
      unicas: json['unicas'] as int? ?? 0,
      faltantes: json['faltantes'] as int? ?? 0,
      progresso: json['progresso'] as int? ?? 0,
      figurinhas: (json['figurinhas'] as List<dynamic>? ?? [])
          .map((f) => Figurinha.fromJson(f as Map<String, dynamic>))
          .toList(),
    );
  }
}
