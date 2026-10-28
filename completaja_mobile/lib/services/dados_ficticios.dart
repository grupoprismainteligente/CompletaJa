import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/album.dart';
import '../models/figurinha.dart';
import '../models/resumo_figurinhas.dart';

/// Dados de mentira para o app funcionar sem banco/API.
/// Quando a API estiver no ar, esta classe é substituída por `AlbumService`
/// (chamadas HTTP) mantendo os mesmos métodos, então as telas quase não mudam.
///
/// É um `ChangeNotifier`: as telas "escutam" e se redesenham quando algo muda
/// (ex.: depois de adicionar um álbum à coleção).
class DadosFicticios extends ChangeNotifier {
  DadosFicticios._();

  /// Instância única (singleton), compartilhada por todas as telas.
  static final DadosFicticios instancia = DadosFicticios._();

  final String nomeUsuario = 'Igor';

  final List<Album> _catalogo = [
    Album(id: 1, nome: 'Copa do Mundo 2026', capa: 'assets/images/copa_2026.jpg', total: 112, usuariosVinculados: 48),
    Album(id: 2, nome: 'Copa do Mundo 2022', capa: 'assets/images/copa_2022.jpg', total: 80, usuariosVinculados: 31),
    Album(id: 3, nome: 'Brasileirão 2026', capa: 'assets/images/brasileirao.png', total: 240, usuariosVinculados: 22),
    Album(id: 4, nome: 'UEFA Champions League', capa: 'assets/images/champions.png', total: 150, usuariosVinculados: 17),
    Album(id: 5, nome: 'Pokémon TCG', capa: 'assets/images/pokemon.png', total: 96, usuariosVinculados: 12),
    Album(id: 6, nome: 'Stars Collection', capa: 'assets/images/stars.jpg', total: 64, usuariosVinculados: 5),
  ];

  // Álbuns que o usuário já coleciona (equivale à tabela UsuarioAlbum).
  final Set<int> _meusIds = {1, 3, 5};

  // Figurinhas por álbum, geradas uma vez e guardadas (equivale à tabela Figurinha).
  final Map<int, List<Figurinha>> _figurinhas = {};

  /// Meus álbuns, do mais popular para o menos (regra do site).
  List<Album> get meusAlbuns => _ordenar(_catalogo.where((a) => _meusIds.contains(a.id)));

  List<Album> get catalogo => _ordenar(_catalogo);

  bool jaColeciona(int albumId) => _meusIds.contains(albumId);

  List<Album> _ordenar(Iterable<Album> albuns) =>
      albuns.toList()..sort((a, b) => b.usuariosVinculados.compareTo(a.usuariosVinculados));

  /// Regra do site: só cria o vínculo se não existir e soma 1 em usuariosVinculados.
  void vincular(int albumId) {
    if (_meusIds.add(albumId)) {
      _catalogo.firstWhere((a) => a.id == albumId).usuariosVinculados += 1;
      notifyListeners();
    }
  }

  /// Todas as figurinhas 1..total de um álbum (as que faltam vêm com quantidade 0).
  ResumoFigurinhas figurinhasDoAlbum(int albumId) {
    final album = _catalogo.firstWhere((a) => a.id == albumId);
    final lista = _figurinhas.putIfAbsent(albumId, () => _gerar(album));
    return ResumoFigurinhas(album: album, figurinhas: lista);
  }

  /// Home: repetidas = soma(quantidade - 1) das que têm mais de 1.
  int get repetidas {
    var soma = 0;
    for (final album in meusAlbuns) {
      soma += figurinhasDoAlbum(album.id).figurinhas.fold(0, (s, f) => s + f.extras);
    }
    return soma;
  }

  /// Home: faltantes = soma dos totais - figurinhas únicas (nunca negativo).
  int get faltantes {
    var soma = 0;
    for (final album in meusAlbuns) {
      soma += figurinhasDoAlbum(album.id).faltantes;
    }
    return max(0, soma);
  }

  // Gera uma coleção parcialmente completa. O Random recebe o id do álbum como
  // "semente", então o resultado é sempre o mesmo a cada abertura do app.
  List<Figurinha> _gerar(Album album) {
    final sorteio = Random(album.id);
    return List.generate(album.total, (i) {
      final numero = i + 1;
      final codigo = numero.toString().padLeft(2, '0'); // regra "D2" do site
      final r = sorteio.nextInt(100);
      final quantidade = r < 35 ? 0 : (r < 80 ? 1 : 2 + sorteio.nextInt(3));
      final nome = quantidade > 0 && sorteio.nextInt(4) == 0 ? _jogadores[sorteio.nextInt(_jogadores.length)] : '';
      return Figurinha(codigo: codigo, nome: nome, quantidade: quantidade);
    });
  }

  static const _jogadores = [
    'Neymar Jr', 'Vini Jr', 'Alisson', 'Casemiro', 'Raphinha', 'Rodrygo',
    'Marquinhos', 'Messi', 'Mbappé', 'Haaland', 'Modric', 'De Bruyne',
  ];

  /// Matches recentes da Home (a tela de Trocas real é V2).
  final List<MatchFicticio> matches = const [
    MatchFicticio(nome: 'Renata', mensagens: 12),
    MatchFicticio(nome: 'Lango', mensagens: 5),
    MatchFicticio(nome: 'Gabi', mensagens: 2),
  ];
}

class MatchFicticio {
  const MatchFicticio({required this.nome, required this.mensagens});
  final String nome;
  final int mensagens;
}
