import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/api_client.dart';
import '../models/usuario.dart';

/// Em que ponto está a sessão. O widget raiz do app escolhe a tela por isso.
enum EstadoSessao { iniciando, deslogado, logado }

/// Onde o token fica guardado entre uma abertura do app e outra.
/// É uma classe abstrata para os testes usarem uma versão em memória.
abstract class ArmazenamentoSessao {
  Future<({String? token, String? usuario})> ler();
  Future<void> salvar(String token, String usuarioJson);
  Future<void> limpar();
}

/// Versão real: `flutter_secure_storage` guarda criptografado (Keystore do Android).
class ArmazenamentoSeguro implements ArmazenamentoSessao {
  static const _chaveToken = 'token';
  static const _chaveUsuario = 'usuario';
  final _storage = const FlutterSecureStorage();

  @override
  Future<({String? token, String? usuario})> ler() async =>
      (token: await _storage.read(key: _chaveToken), usuario: await _storage.read(key: _chaveUsuario));

  @override
  Future<void> salvar(String token, String usuarioJson) async {
    await _storage.write(key: _chaveToken, value: token);
    await _storage.write(key: _chaveUsuario, value: usuarioJson);
  }

  @override
  Future<void> limpar() async {
    await _storage.delete(key: _chaveToken);
    await _storage.delete(key: _chaveUsuario);
  }
}

/// Login, logout e restauração da sessão. É um `ChangeNotifier`: quem escuta
/// (via `provider`) se redesenha quando o estado muda, por isso o login e o
/// logout trocam de tela sozinhos, sem `Navigator` espalhado pelo app.
class AuthService extends ChangeNotifier {
  AuthService(this._api, {ArmazenamentoSessao? armazenamento})
      : _armazenamento = armazenamento ?? ArmazenamentoSeguro() {
    // Qualquer chamada da API que receber 401 derruba a sessão e volta ao login.
    _api.aoNaoAutorizado = _sessaoExpirou;
  }

  final ApiClient _api;
  final ArmazenamentoSessao _armazenamento;

  EstadoSessao _estado = EstadoSessao.iniciando;
  Usuario? _usuario;

  /// O mesmo cliente HTTP (com o token da sessão) é reaproveitado pelos outros serviços.
  ApiClient get api => _api;

  EstadoSessao get estado => _estado;
  Usuario? get usuario => _usuario;

  /// Chamado uma vez ao abrir o app. Se há token salvo, entra direto (sem
  /// esperar a rede: se o token já venceu, a 1ª chamada da API responde 401
  /// e `_sessaoExpirou` leva ao login).
  Future<void> restaurarSessao() async {
    try {
      final salvo = await _armazenamento.ler();
      if (salvo.token != null && salvo.usuario != null) {
        _usuario = Usuario.fromJson(jsonDecode(salvo.usuario!) as Map<String, dynamic>);
        _api.token = salvo.token;
        _estado = EstadoSessao.logado;
        notifyListeners();
        return;
      }
    } catch (_) {
      // Armazenamento corrompido ou JSON inválido: começa deslogado.
      await _limparSessao();
    }
    _estado = EstadoSessao.deslogado;
    notifyListeners();
  }

  /// `POST /api/auth/login`. Em caso de erro lança `ApiException` com a mensagem
  /// para a tela mostrar (senha errada, sem rede, servidor dormindo...).
  Future<void> entrar(String email, String senha) async {
    final resposta = await _api.post('/api/auth/login', corpo: {'email': email.trim(), 'senha': senha})
        as Map<String, dynamic>;

    final token = resposta['token'] as String;
    final usuario = Usuario.fromJson(resposta['usuario'] as Map<String, dynamic>);

    _api.token = token;
    _usuario = usuario;
    await _armazenamento.salvar(token, jsonEncode(usuario.toJson()));
    _estado = EstadoSessao.logado;
    notifyListeners();
  }

  Future<void> sair() async {
    await _limparSessao();
    _estado = EstadoSessao.deslogado;
    notifyListeners();
  }

  void _sessaoExpirou() {
    // Só age se ainda estava logado; evita notificar duas vezes quando várias
    // chamadas simultâneas recebem 401.
    if (_estado == EstadoSessao.logado) sair();
  }

  Future<void> _limparSessao() async {
    _api.token = null;
    _usuario = null;
    try {
      await _armazenamento.limpar();
    } catch (_) {
      // Se nem limpar o armazenamento der certo, seguimos: o token em memória já foi zerado.
    }
  }
}
