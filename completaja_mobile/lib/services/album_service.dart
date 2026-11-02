import '../core/api_client.dart';
import '../models/album.dart';
import '../models/figurinha.dart';
import '../models/resumo_figurinhas.dart';
import '../models/resumo_home.dart';

/// Todas as chamadas de coleção do app. Cada método é uma chamada à API; não
/// guarda cache de propósito: as telas sempre mostram o que está no banco.
/// (Substitui o antigo `DadosFicticios`.)
class AlbumService {
  AlbumService(this._api);

  final ApiClient _api;

  /// `GET /api/home`
  Future<ResumoHome> home() async => ResumoHome.fromJson(await _api.get('/api/home') as Map<String, dynamic>);

  /// `GET /api/albuns/meus`
  Future<List<Album>> meusAlbuns() async => _lista(await _api.get('/api/albuns/meus'));

  /// `GET /api/albuns/catalogo`
  Future<List<Album>> catalogo() async => _lista(await _api.get('/api/albuns/catalogo'));

  /// `POST /api/albuns/{id}/vincular` (idempotente no servidor).
  Future<void> vincular(int albumId) async {
    await _api.post('/api/albuns/$albumId/vincular');
  }

  /// `GET /api/albuns/{id}/figurinhas`: a grade completa 1..total.
  Future<ResumoFigurinhas> figurinhas(int albumId) async =>
      ResumoFigurinhas.fromJson(await _api.get('/api/albuns/$albumId/figurinhas') as Map<String, dynamic>);

  /// `PUT /api/albuns/{id}/figurinhas/{codigo}`: devolve a figurinha como ficou no banco.
  Future<Figurinha> salvarFigurinha(int albumId, String codigo, {required int quantidade, required String nome}) async =>
      Figurinha.fromJson(
        await _api.put('/api/albuns/$albumId/figurinhas/$codigo', corpo: {'quantidade': quantidade, 'nome': nome})
            as Map<String, dynamic>,
      );

  List<Album> _lista(dynamic json) =>
      (json as List<dynamic>).map((a) => Album.fromJson(a as Map<String, dynamic>)).toList();
}
