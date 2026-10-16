/// Um álbum do catálogo. Espelha o `AlbumDto` da API (a capa aqui é um asset local).
class Album {
  Album({
    required this.id,
    required this.nome,
    required this.capa,
    required this.total,
    required this.usuariosVinculados,
  });

  final int id;
  final String nome;

  /// Caminho do asset da capa (nos dados reais será a URL relativa vinda da API).
  final String capa;
  final int total;

  /// Não é final: vincular um álbum soma 1 aqui, igual à regra do site.
  int usuariosVinculados;
}
