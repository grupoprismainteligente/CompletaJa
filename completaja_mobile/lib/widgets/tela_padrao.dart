import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/config.dart';
import '../core/theme.dart';
import '../screens/em_breve_screen.dart';
import '../screens/home_screen.dart';
import '../screens/meus_albuns_screen.dart';
import '../services/auth_service.dart';
import 'aviso.dart';

/// As 4 abas da barra inferior.
enum Aba { home, albuns, locais, trocas }

/// Moldura que toda tela do app usa, igual ao `_Layout.cshtml` do site:
/// cabeçalho (voltar, foto, logo, Sair, sino) em cima e barra de 4 abas embaixo.
class TelaPadrao extends StatelessWidget {
  const TelaPadrao({super.key, required this.aba, required this.corpo});

  /// Aba destacada na barra inferior.
  final Aba aba;
  final Widget corpo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCores.superficie,
      // SafeArea evita que o conteúdo fique embaixo da barra de status/gestos do celular.
      body: SafeArea(
        child: Column(
          children: [
            const _Cabecalho(),
            // Expanded: o corpo ocupa todo o espaço entre o cabeçalho e a barra inferior.
            Expanded(child: corpo),
            _BarraInferior(aba: aba),
          ],
        ),
      ),
    );
  }
}

class _Cabecalho extends StatelessWidget {
  const _Cabecalho();

  Future<void> _sair(BuildContext context) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: const Text('Tem certeza que deseja sair do sistema?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('OK')),
        ],
      ),
    );
    if (confirmou == true && context.mounted) {
      // Apaga a sessão. O ouvinte de sessão (main.dart) fecha todas as telas e volta ao login.
      await context.read<AuthService>().sair();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppEspacos.lateral),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppCores.bordaSuave)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // O botão de voltar só aparece se há para onde voltar.
              if (Navigator.of(context).canPop())
                InkWell(
                  onTap: () => Navigator.of(context).maybePop(),
                  child: const Padding(
                    padding: EdgeInsets.only(right: AppEspacos.compacto),
                    child: Icon(Icons.arrow_back, color: AppCores.textoSuave),
                  ),
                ),
              GestureDetector(
                onTap: () => mostrarAviso(context, 'A edição de perfil fica disponível no site.'),
                child: Container(
                  width: AppTamanhos.avatarTopo,
                  height: AppTamanhos.avatarTopo,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppCores.primariaClara,
                    border: Border.all(color: AppCores.primaria, width: 2),
                  ),
                  child: const _FotoUsuario(),
                ),
              ),
              const SizedBox(width: AppEspacos.compacto),
              Text('CompletaJá', style: AppTextos.logo),
            ],
          ),
          Row(
            children: [
              InkWell(
                onTap: () => _sair(context),
                child: Row(
                  children: [
                    const Icon(Icons.logout, size: 16, color: AppCores.textoSuave),
                    const SizedBox(width: AppEspacos.minimo),
                    Text('Sair', style: AppTextos.sair),
                  ],
                ),
              ),
              const SizedBox(width: AppEspacos.medio),
              const Icon(Icons.notifications_none, color: AppCores.textoSuave),
            ],
          ),
        ],
      ),
    );
  }
}

/// Foto do usuário logado no cabeçalho. Se não tiver foto ou a imagem falhar
/// (sem rede, link quebrado), mostra o ícone de pessoa no lugar.
class _FotoUsuario extends StatelessWidget {
  const _FotoUsuario();

  @override
  Widget build(BuildContext context) {
    const placeholder = Icon(Icons.person, color: AppCores.primaria);
    final url = AppConfig.urlImagem(context.watch<AuthService>().usuario?.fotoUrl);
    if (url == null) return placeholder;

    // ClipOval recorta a imagem em círculo, igual ao contorno do avatar.
    return ClipOval(
      child: Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder,
      ),
    );
  }
}

class _BarraInferior extends StatelessWidget {
  const _BarraInferior({required this.aba});

  final Aba aba;

  // Trocar de aba substitui a tela atual (pushReplacement) em vez de empilhar,
  // então a pilha não cresce a cada toque na barra.
  void _ir(BuildContext context, Aba destino) {
    if (destino == aba) return;
    final Widget tela = switch (destino) {
      Aba.home => const HomeScreen(),
      Aba.albuns => const MeusAlbunsScreen(),
      Aba.locais => const EmBreveScreen(
          aba: Aba.locais,
          titulo: 'Locais',
          icone: Icons.pin_drop_outlined,
          descricao: 'Pontos seguros para encontrar outros colecionadores e trocar figurinhas.',
        ),
      Aba.trocas => const EmBreveScreen(
          aba: Aba.trocas,
          titulo: 'Trocas',
          icone: Icons.forum_outlined,
          descricao: 'Encontre quem tem as figurinhas que faltam para você.',
        ),
    };
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => tela));
  }

  Widget _item(BuildContext context, Aba destino, IconData icone, String rotulo) {
    final cor = destino == aba ? AppCores.atalho : AppCores.textoDesabilitado;
    return Expanded(
      child: InkWell(
        onTap: () => _ir(context, destino),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 22, color: cor),
            const SizedBox(height: AppEspacos.minimo),
            Text(rotulo, style: AppTextos.navegacao.copyWith(color: cor)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppEspacos.compacto),
      decoration: const BoxDecoration(
        color: AppCores.superficie,
        border: Border(top: BorderSide(color: AppCores.bordaSuave)),
      ),
      child: Row(
        children: [
          _item(context, Aba.home, Icons.home, 'Home'),
          _item(context, Aba.albuns, Icons.menu_book, 'Álbuns'),
          _item(context, Aba.locais, Icons.pin_drop, 'Locais'),
          _item(context, Aba.trocas, Icons.forum, 'Trocas'),
        ],
      ),
    );
  }
}
