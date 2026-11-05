import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/api_client.dart';
import 'core/theme.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/album_service.dart';
import 'services/auth_service.dart';
import 'widgets/carregando.dart';

void main() {
  // Necessário antes de usar plugins (como o armazenamento seguro) antes do runApp.
  WidgetsFlutterBinding.ensureInitialized();

  final auth = AuthService(ApiClient())..restaurarSessao();
  runApp(CompletaJaApp(auth: auth));
}

class CompletaJaApp extends StatefulWidget {
  const CompletaJaApp({super.key, required this.auth});

  /// Recebido de fora (e não criado aqui) para os testes poderem passar um de mentira.
  final AuthService auth;

  @override
  State<CompletaJaApp> createState() => _CompletaJaAppState();
}

class _CompletaJaAppState extends State<CompletaJaApp> {
  // Permite navegar sem ter um `context` de tela (usado quando a sessão cai).
  final _navegador = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    // O Provider deixa o AuthService acessível em qualquer tela abaixo (context.read / context.watch).
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: widget.auth),
        // Reaproveita o ApiClient do login, que já carrega o token.
        Provider<AlbumService>(create: (_) => AlbumService(widget.auth.api)),
      ],
      child: MaterialApp(
        title: 'CompletaJá',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.claro,
        navigatorKey: _navegador,
        builder: (context, tela) => _OuvinteDeSessao(navegador: _navegador, child: tela!),
        home: const PortaDeEntrada(),
      ),
    );
  }
}

/// Decide qual tela mostrar pelo estado da sessão. Como escuta o `AuthService`,
/// entrar e sair trocam de tela sozinhos.
class PortaDeEntrada extends StatelessWidget {
  const PortaDeEntrada({super.key});

  @override
  Widget build(BuildContext context) {
    // `watch` redesenha este widget toda vez que o AuthService avisa uma mudança.
    final estado = context.watch<AuthService>().estado;
    return switch (estado) {
      EstadoSessao.iniciando => const TelaCarregando(),
      EstadoSessao.deslogado => const LoginScreen(),
      EstadoSessao.logado => const HomeScreen(),
    };
  }
}

/// Quando a sessão cai (botão Sair ou API respondendo 401), volta ao login de
/// QUALQUER tela. Sem isso, trocar de aba (que substitui a rota raiz) deixaria o
/// usuário preso nas telas internas depois de sair.
class _OuvinteDeSessao extends StatefulWidget {
  const _OuvinteDeSessao({required this.navegador, required this.child});

  final GlobalKey<NavigatorState> navegador;
  final Widget child;

  @override
  State<_OuvinteDeSessao> createState() => _OuvinteDeSessaoState();
}

class _OuvinteDeSessaoState extends State<_OuvinteDeSessao> {
  late final AuthService _auth;
  late EstadoSessao _anterior;

  @override
  void initState() {
    super.initState();
    _auth = context.read<AuthService>();
    _anterior = _auth.estado;
    _auth.addListener(_aoMudarSessao);
  }

  @override
  void dispose() {
    _auth.removeListener(_aoMudarSessao);
    super.dispose();
  }

  void _aoMudarSessao() {
    final atual = _auth.estado;
    if (_anterior == EstadoSessao.logado && atual == EstadoSessao.deslogado) {
      // Joga fora toda a pilha de telas e recomeça pela PortaDeEntrada (que mostra o login).
      widget.navegador.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const PortaDeEntrada()),
        (rota) => false,
      );
    }
    _anterior = atual;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}