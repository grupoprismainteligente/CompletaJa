import 'dart:async';

import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/config.dart';
import '../core/theme.dart';

/// Busca um dado na API e cuida dos estados que toda tela precisa: carregando,
/// erro (com "Tentar de novo") e pronto. O estado "vazio" fica por conta de quem
/// usa, pois a mensagem muda de tela para tela.
///
/// Use uma `GlobalKey<CarregaDadosState<T>>` para pedir `recarregar()` de fora
/// (ex.: ao voltar do catálogo para Meus Álbuns).
class CarregaDados<T> extends StatefulWidget {
  const CarregaDados({super.key, required this.carregar, required this.construir});

  final Future<T> Function() carregar;
  final Widget Function(BuildContext context, T dados) construir;

  @override
  State<CarregaDados<T>> createState() => CarregaDadosState<T>();
}

class CarregaDadosState<T> extends State<CarregaDados<T>> {
  late Future<T> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = widget.carregar();
  }

  void recarregar() => setState(() => _futuro = widget.carregar());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _futuro,
      builder: (context, snapshot) {
        if (snapshot.hasError) return _Erro(erro: snapshot.error!, aoTentarDeNovo: recarregar);
        if (snapshot.connectionState != ConnectionState.done) return const _Aguardando();
        return widget.construir(context, snapshot.data as T);
      },
    );
  }
}

/// Spinner que, depois de uns segundos, avisa que o servidor gratuito do Render está acordando.
class _Aguardando extends StatefulWidget {
  const _Aguardando();

  @override
  State<_Aguardando> createState() => _AguardandoState();
}

class _AguardandoState extends State<_Aguardando> {
  bool _demorando = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(AppConfig.avisoServidorAcordando, () {
      if (mounted) setState(() => _demorando = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppCores.primaria),
          if (_demorando) ...[
            const SizedBox(height: AppEspacos.medio),
            Text(
              'Acordando o servidor...\nNa primeira vez pode levar até um minuto.',
              textAlign: TextAlign.center,
              style: AppTextos.emBreveTexto,
            ),
          ],
        ],
      ),
    );
  }
}

class _Erro extends StatelessWidget {
  const _Erro({required this.erro, required this.aoTentarDeNovo});

  final Object erro;
  final VoidCallback aoTentarDeNovo;

  @override
  Widget build(BuildContext context) {
    final e = erro;
    final mensagem = e is ApiException ? e.mensagem : 'Algo deu errado. Tente de novo.';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppEspacos.lateral),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 40, color: AppCores.textoDesabilitado),
            const SizedBox(height: AppEspacos.medio),
            Text(mensagem, textAlign: TextAlign.center, style: AppTextos.vazioTexto),
            const SizedBox(height: AppEspacos.medio),
            ElevatedButton(onPressed: aoTentarDeNovo, child: const Text('Tentar de novo')),
          ],
        ),
      ),
    );
  }
}
