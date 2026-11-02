/// Um álbum do catálogo. Espelha o `AlbumDto` / `AlbumCatalogoDto` da API.
class Album {
  const Album({
    required this.id,
    required this.nome,
    required this.capaUrl,
    required this.total,
    required this.usuariosVinculados,
    this.jaColeciona = false,
  });

  final int id;
  final String nome;

  /// URL completa (Cloudinary) ou relativa; use `AppConfig.urlImagem` para montar o endereço final.
  final String? capaUrl;
  final int total;
  final int usuariosVinculados;

  /// Só vem preenchido pelo catálogo.
  final bool jaColeciona;

  factory Album.fromJson(Map<String, dynamic> json) => Album(
        id: json['id'] as int,
        nome: json['nome'] as String? ?? '',
        capaUrl: json['capaUrl'] as String?,
        total: json['total'] as int? ?? 0,
        usuariosVinculados: json['usuariosVinculados'] as int? ?? 0,
        jaColeciona: json['jaColeciona'] as bool? ?? false,
      );
}
