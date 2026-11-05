import 'dart:convert';

import 'package:completaja_mobile/core/api_client.dart';
import 'package:completaja_mobile/core/config.dart';
import 'package:completaja_mobile/main.dart';
import 'package:completaja_mobile/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Armazenamento em memória: nos testes não existe o Keystore do Android.
class ArmazenamentoMemoria implements ArmazenamentoSessao {
  String? token;
  String? usuario;

  @override
  Future<({String? token, String? usuario})> ler() async => (token: token, usuario: usuario);

  @override
  Future<void> salvar(String token, String usuarioJson) async {
    this.token = token;
    usuario = usuarioJson;
  }

  @override
  Future<void> limpar() async {
    token = null;
    usuario = null;
  }
}

http.Response _json(int status, Object corpo) => http.Response.bytes(
      utf8.encode(jsonEncode(corpo)),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

/// Servidor de mentira que imita a API: aceita só igor@teste.com / 123.
MockClient _servidorDeMentira({List<http.BaseRequest>? registro}) => MockClient((request) async {
      registro?.add(request);
      if (request.url.path == '/api/auth/login') {
        // O MockClient já entrega a Request pronta; o corpo está em `body`.
        final corpo = jsonDecode(request.body) as Map<String, dynamic>;
        if (corpo['email'] == 'igor@teste.com' && corpo['senha'] == '123') {
          return _json(200, {
            'token': 'token-de-teste',
            'usuario': {'id': 7, 'nome': 'Igomes', 'fotoUrl': '/images/default-avatar.png'},
          });
        }
        return _json(401, {'mensagem': 'E-mail ou senha inválidos.'});
      }
      if (request.url.path == '/api/home') return _json(200, {'nome': 'Igomes', 'repetidas': 4, 'faltantes': 9});
      if (request.url.path == '/api/albuns/meus') {
        return _json(200, [
          {'id': 1, 'nome': 'Álbum do Banco', 'capaUrl': null, 'total': 3, 'usuariosVinculados': 2},
        ]);
      }
      if (request.method == 'PUT' && request.url.path == '/api/albuns/1/figurinhas/01') {
        return _json(200, {'codigo': '01', 'nome': '', 'quantidade': 1});
      }
      if (request.method == 'PUT' && request.url.path == '/api/albuns/1/figurinhas/03') {
        return _json(500, {});
      }
      if (request.url.path == '/api/albuns/1/figurinhas') {
        return _json(200, {
          'album': {'id': 1, 'nome': 'Álbum do Banco', 'capaUrl': null},
          'total': 3,
          'unicas': 2,
          'faltantes': 1,
          'progresso': 67,
          'figurinhas': [
            {'codigo': '01', 'nome': '', 'quantidade': 0},
            {'codigo': '02', 'nome': '', 'quantidade': 1},
            {'codigo': '03', 'nome': '', 'quantidade': 3},
          ],
        });
      }
      return _json(404, {'mensagem': 'não existe'});
    });

void main() {
  // Nos testes não há internet; sem isso o google_fonts tentaria baixar a Inter.
  GoogleFonts.config.allowRuntimeFetching = false;

  group('AppConfig', () {
    test('urlImagem mantém URL completa (Cloudinary) e prefixa a relativa', () {
      expect(AppConfig.urlImagem('https://res.cloudinary.com/x/a.png'), 'https://res.cloudinary.com/x/a.png');
      expect(AppConfig.urlImagem('/images/default-avatar.png'), '${AppConfig.urlBase}/images/default-avatar.png');
      expect(AppConfig.urlImagem(null), isNull);
      expect(AppConfig.urlImagem(''), isNull);
    });
  });

  group('AuthService', () {
    test('login correto guarda a sessão e passa a enviar o token', () async {
      final registro = <http.BaseRequest>[];
      final api = ApiClient(cliente: _servidorDeMentira(registro: registro));
      final memoria = ArmazenamentoMemoria();
      final auth = AuthService(api, armazenamento: memoria);

      await auth.entrar('  igor@teste.com ', '123'); // espaço sobrando é cortado
      expect(auth.estado, EstadoSessao.logado);
      expect(auth.usuario?.nome, 'Igomes');
      expect(memoria.token, 'token-de-teste');

      await api.get('/api/home');
      expect(registro.last.headers['Authorization'], 'Bearer token-de-teste');
    });

    test('resposta que não é JSON (página do site) vira mensagem amigável', () async {
      final api = ApiClient(cliente: MockClient((_) async => http.Response('<html>login</html>', 200)));
      final auth = AuthService(api, armazenamento: ArmazenamentoMemoria());
      await expectLater(auth.entrar('igor@teste.com', '123'), throwsA(isA<ApiException>()));
      expect(auth.estado, isNot(EstadoSessao.logado));
    });

    test('senha errada lança ApiException com a mensagem da API e não entra', () async {
      final auth = AuthService(ApiClient(cliente: _servidorDeMentira()), armazenamento: ArmazenamentoMemoria());
      await expectLater(
        auth.entrar('igor@teste.com', 'errada'),
        throwsA(isA<ApiException>().having((e) => e.mensagem, 'mensagem', 'E-mail ou senha inválidos.')),
      );
      expect(auth.estado, isNot(EstadoSessao.logado));
    });

    test('sem rede vira uma mensagem amigável', () async {
      final api = ApiClient(cliente: MockClient((_) async => throw http.ClientException('sem rede')));
      final auth = AuthService(api, armazenamento: ArmazenamentoMemoria());
      await expectLater(
        auth.entrar('igor@teste.com', '123'),
        throwsA(isA<ApiException>().having((e) => e.mensagem, 'mensagem', contains('conectar ao servidor'))),
      );
    });

    test('restaurarSessao entra direto quando há token salvo', () async {
      final memoria = ArmazenamentoMemoria()
        ..token = 'token-salvo'
        ..usuario = jsonEncode({'id': 7, 'nome': 'Igomes', 'fotoUrl': null});
      final auth = AuthService(ApiClient(cliente: _servidorDeMentira()), armazenamento: memoria);

      await auth.restaurarSessao();
      expect(auth.estado, EstadoSessao.logado);
      expect(auth.usuario?.nome, 'Igomes');
    });

    test('restaurarSessao sem token (ou com dado corrompido) começa deslogado', () async {
      final vazio = AuthService(ApiClient(cliente: _servidorDeMentira()), armazenamento: ArmazenamentoMemoria());
      await vazio.restaurarSessao();
      expect(vazio.estado, EstadoSessao.deslogado);

      final corrompido = ArmazenamentoMemoria()
        ..token = 't'
        ..usuario = '{isso não é json';
      final auth = AuthService(ApiClient(cliente: _servidorDeMentira()), armazenamento: corrompido);
      await auth.restaurarSessao();
      expect(auth.estado, EstadoSessao.deslogado);
      expect(corrompido.token, isNull); // limpou o lixo
    });

    test('401 numa chamada autenticada derruba a sessão', () async {
      // Servidor que aceita o login mas responde 401 em tudo depois (token vencido).
      final api = ApiClient(cliente: MockClient((request) async {
        if (request.url.path == '/api/auth/login') {
          return _json(200, {
            'token': 'vencido',
            'usuario': {'id': 1, 'nome': 'A', 'fotoUrl': null},
          });
        }
        return _json(401, {});
      }));
      final memoria = ArmazenamentoMemoria();
      final auth = AuthService(api, armazenamento: memoria);
      await auth.entrar('a@a.com', 'x');
      expect(auth.estado, EstadoSessao.logado);

      await expectLater(api.get('/api/home'), throwsA(isA<ApiException>()));
      await Future<void>.delayed(Duration.zero); // deixa o sair() assíncrono terminar
      expect(auth.estado, EstadoSessao.deslogado);
      expect(memoria.token, isNull);
    });
  });

  group('Telas', () {
    // Tamanho de celular, para a tela não estourar como no tamanho padrão do teste.
    void configurarTela(WidgetTester tester) {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.reset);

      // No teste a fonte é a "Ahem" (cada letra é um quadrado largo), então textos
      // estouram a largura só aqui. Ignoramos apenas esse aviso; o resto continua falhando.
      final tratadorOriginal = FlutterError.onError;
      FlutterError.onError = (detalhes) {
        if (detalhes.exceptionAsString().contains('overflowed')) return;
        tratadorOriginal?.call(detalhes);
      };
    }

    AuthService criarAuth(ArmazenamentoMemoria memoria) =>
        AuthService(ApiClient(cliente: _servidorDeMentira()), armazenamento: memoria);

    testWidgets('login valida campos, mostra erro da API, entra e navega; sair volta ao login', (tester) async {
      configurarTela(tester);
      final memoria = ArmazenamentoMemoria();
      final auth = criarAuth(memoria);
      await tester.pumpWidget(CompletaJaApp(auth: auth));
      await auth.restaurarSessao();
      await tester.pumpAndSettle();
      expect(find.text('Complete seu álbum com amigos!'), findsOneWidget);

      // Vazio: erro local, sem chamar a API.
      await tester.tap(find.text('Entrar').last);
      await tester.pump();
      expect(find.text('Informe e-mail e senha.'), findsOneWidget);

      // Senha errada: mostra a mensagem que veio da API.
      await tester.enterText(find.byType(TextField).first, 'igor@teste.com');
      await tester.enterText(find.byType(TextField).last, 'errada');
      await tester.tap(find.text('Entrar').last);
      await tester.pumpAndSettle();
      expect(find.text('E-mail ou senha inválidos.'), findsOneWidget);

      // Senha certa: Home com o nome vindo da API.
      await tester.enterText(find.byType(TextField).last, '123');
      await tester.tap(find.text('Entrar').last);
      await tester.pumpAndSettle();
      expect(find.textContaining('Olá,'), findsOneWidget);
      expect(find.textContaining('Igomes'), findsOneWidget);
      expect(memoria.token, 'token-de-teste');

      // Contadores da Home vêm da API.
      expect(find.text('4'), findsOneWidget);
      expect(find.text('9'), findsOneWidget);

      // Navegação com dados da API.
      await tester.tap(find.text('Álbuns'));
      await tester.pumpAndSettle();
      expect(find.text('Meus Álbuns'), findsOneWidget);
      await tester.tap(find.text('Álbum do Banco'));
      await tester.pumpAndSettle();
      expect(find.text('Progresso Total'), findsOneWidget);
      expect(find.text('67%'), findsOneWidget);

      // Editar a figurinha 01 (faltante): +1 e Salvar. O progresso sobe na hora.
      expect(find.text('2 / 3 figurinhas'), findsOneWidget);
      await tester.tap(find.text('01'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pump();
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();
      expect(find.text('3 / 3 figurinhas'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);

      // Editar a 03 (3 em mãos, selo +2) para 2, com a API falhando: volta a +2 e avisa.
      await tester.tap(find.text('03'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.remove_circle_outline));
      await tester.pump();
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();
      expect(find.text('+2'), findsOneWidget);
      expect(find.textContaining('Não foi possível salvar a figurinha 03'), findsOneWidget);
      expect(find.text('3 / 3 figurinhas'), findsOneWidget); // o progresso da 01 não foi perdido

      // Sair: confirma no diálogo e volta ao login com a sessão apagada.
      await tester.tap(find.text('Sair'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('Complete seu álbum com amigos!'), findsOneWidget);
      expect(memoria.token, isNull);
    });

    testWidgets('com token salvo o app abre direto na Home', (tester) async {
      configurarTela(tester);
      final memoria = ArmazenamentoMemoria()
        ..token = 'token-salvo'
        ..usuario = jsonEncode({'id': 7, 'nome': 'Igomes', 'fotoUrl': null});
      final auth = criarAuth(memoria);

      await tester.pumpWidget(CompletaJaApp(auth: auth));
      // Antes de restaurar, mostra o carregando (não pisca a tela de login).
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Complete seu álbum com amigos!'), findsNothing);

      await auth.restaurarSessao();
      await tester.pumpAndSettle();
      expect(find.textContaining('Igomes'), findsOneWidget);
    });
  });
}
