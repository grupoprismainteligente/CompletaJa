import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'config.dart';

/// Erro de uma chamada à API, já com mensagem pronta para mostrar ao usuário.
class ApiException implements Exception {
  ApiException(this.mensagem, {this.statusCode});

  final String mensagem;

  /// Código HTTP, quando o servidor chegou a responder (null = sem rede / timeout).
  final int? statusCode;

  @override
  String toString() => mensagem;
}

/// Cliente HTTP único do app. Todas as chamadas à API passam por aqui, então
/// token, timeout e tratamento de erro ficam em um lugar só.
class ApiClient {
  ApiClient({http.Client? cliente}) : _cliente = cliente ?? http.Client();

  // Recebe o cliente por parâmetro para os testes poderem trocar por um de mentira.
  final http.Client _cliente;

  /// Token JWT da sessão atual. O `AuthService` preenche ao entrar e limpa ao sair.
  String? token;

  /// Chamado quando a API responde 401 numa chamada autenticada (token vencido
  /// ou inválido). O `AuthService` usa isso para voltar ao login.
  void Function()? aoNaoAutorizado;

  Future<dynamic> get(String caminho) => _enviar('GET', caminho);

  Future<dynamic> post(String caminho, {Object? corpo}) => _enviar('POST', caminho, corpo: corpo);

  Future<dynamic> put(String caminho, {Object? corpo}) => _enviar('PUT', caminho, corpo: corpo);

  Future<dynamic> _enviar(String metodo, String caminho, {Object? corpo}) async {
    final requisicao = http.Request(metodo, Uri.parse('${AppConfig.urlBase}$caminho'));
    requisicao.headers['Accept'] = 'application/json';
    if (corpo != null) {
      requisicao.headers['Content-Type'] = 'application/json';
      requisicao.body = jsonEncode(corpo);
    }
    final tokenAtual = token;
    if (tokenAtual != null) requisicao.headers['Authorization'] = 'Bearer $tokenAtual';

    final http.Response resposta;
    try {
      resposta = await http.Response.fromStream(await _cliente.send(requisicao).timeout(AppConfig.timeout));
    } on TimeoutException {
      throw ApiException('O servidor demorou demais para responder. Tente de novo.');
    } on SocketException {
      throw ApiException('Não foi possível conectar ao servidor. Verifique sua internet.');
    } on http.ClientException {
      throw ApiException('Não foi possível conectar ao servidor. Verifique sua internet.');
    }

    // 401 com token enviado = sessão vencida. No login (sem token) o 401 é "senha errada".
    if (resposta.statusCode == 401 && tokenAtual != null) {
      aoNaoAutorizado?.call();
      throw ApiException('Sua sessão expirou. Entre novamente.', statusCode: 401);
    }

    if (resposta.statusCode >= 200 && resposta.statusCode < 300) {
      // 204 (sem conteúdo) devolve null.
      if (resposta.body.isEmpty) return null;
      return jsonDecode(utf8.decode(resposta.bodyBytes));
    }

    throw ApiException(_mensagemDeErro(resposta), statusCode: resposta.statusCode);
  }

  /// A API manda `{ "mensagem": "..." }` nos erros; senão usamos um texto genérico.
  String _mensagemDeErro(http.Response resposta) {
    try {
      final json = jsonDecode(utf8.decode(resposta.bodyBytes));
      if (json is Map && json['mensagem'] is String) return json['mensagem'] as String;
    } catch (_) {
      // Corpo que não é JSON: cai no texto genérico abaixo.
    }
    if (resposta.statusCode >= 500) return 'O servidor teve um problema. Tente de novo em instantes.';
    return 'Não foi possível concluir a operação (erro ${resposta.statusCode}).';
  }
}
