import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../services/auth_service.dart';
import '../services/dados_ficticios.dart';
import '../widgets/tela_padrao.dart';
import 'em_breve_screen.dart';
import 'meus_albuns_screen.dart';

/// Home: saudação, contadores de repetidas/faltantes, atalhos e matches recentes.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dados = DadosFicticios.instancia;

    return TelaPadrao(
      aba: Aba.home,
      // ListenableBuilder redesenha quando os dados mudam (ex.: álbum adicionado
      // altera os contadores).
      corpo: ListenableBuilder(
        listenable: dados,
        builder: (context, _) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppEspacos.lateral),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppEspacos.lateral),
              // O nome já é o do usuário real (vem do login). Os contadores abaixo
              // ainda são fictícios até a etapa de ligar a Home à API.
              Text('Olá,\n${context.watch<AuthService>().usuario?.nome ?? ''}!', style: AppTextos.boasVindas),
              const SizedBox(height: AppEspacos.enorme),
              _estatisticas(dados),
              const SizedBox(height: AppEspacos.enorme),
              Text('Atalhos', style: AppTextos.secao),
              const SizedBox(height: AppEspacos.medio),
              _atalhoPrincipal(context),
              const SizedBox(height: AppEspacos.medio),
              _atalhosSecundarios(context),
              _matchesRecentes(context, dados),
              const SizedBox(height: AppEspacos.grande),
            ],
          ),
        ),
      ),
    );
  }

  Widget _estatisticas(DadosFicticios dados) {
    return Row(
      children: [
        Expanded(
          child: _cardEstatistica(
            numero: dados.repetidas,
            rotulo: 'REPETIDAS',
            fundo: AppCores.primariaClara,
          ),
        ),
        const SizedBox(width: AppEspacos.grande),
        Expanded(
          child: _cardEstatistica(
            numero: dados.faltantes,
            rotulo: 'FALTANTES',
            corNumero: AppCores.erro,
            borda: AppCores.borda,
          ),
        ),
      ],
    );
  }

  Widget _cardEstatistica({
    required int numero,
    required String rotulo,
    Color? fundo,
    Color? borda,
    Color? corNumero,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppEspacos.lateral),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(AppRaios.grande),
        border: borda == null ? null : Border.all(color: borda),
      ),
      child: Column(
        children: [
          Text(
            '$numero',
            style: AppTextos.estatisticaNumero.copyWith(color: corNumero),
          ),
          const SizedBox(height: AppEspacos.minimo),
          Text(rotulo, style: AppTextos.estatisticaRotulo),
        ],
      ),
    );
  }

  Widget _atalhoPrincipal(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRaios.grande),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const MeusAlbunsScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppEspacos.lateral),
        decoration: BoxDecoration(
          color: AppCores.atalho,
          borderRadius: BorderRadius.circular(AppRaios.grande),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Meus Álbuns', style: AppTextos.atalhoTitulo),
                const SizedBox(height: AppEspacos.minimo),
                Text('Gerencie suas coleções', style: AppTextos.atalhoSubtitulo),
              ],
            ),
            const Icon(Icons.chevron_right, color: AppCores.superficie),
          ],
        ),
      ),
    );
  }

  Widget _atalhosSecundarios(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _caixaAtalho(
            context,
            fundo: AppCores.repetida,
            corIcone: AppCores.repetidaTexto,
            icone: Icons.location_on,
            titulo: 'Gerenciar Locais',
            estiloTitulo: AppTextos.caixaTitulo,
            destino: const EmBreveScreen(
              aba: Aba.locais,
              titulo: 'Locais',
              icone: Icons.pin_drop_outlined,
              descricao: 'Pontos seguros para encontrar outros colecionadores e trocar figurinhas.',
            ),
          ),
        ),
        const SizedBox(width: AppEspacos.medio),
        Expanded(
          child: _caixaAtalho(
            context,
            fundo: AppCores.azulSuave,
            corIcone: AppCores.azulEscuro,
            icone: Icons.handshake,
            titulo: 'Encontrar Trocas',
            subtitulo: 'Matches automáticos',
            estiloTitulo: AppTextos.caixaTituloAzul,
            destino: const EmBreveScreen(
              aba: Aba.trocas,
              titulo: 'Trocas',
              icone: Icons.forum_outlined,
              descricao: 'Encontre quem tem as figurinhas que faltam para você.',
            ),
          ),
        ),
      ],
    );
  }

  Widget _caixaAtalho(
    BuildContext context, {
    required Color fundo,
    required Color corIcone,
    required IconData icone,
    required String titulo,
    required TextStyle estiloTitulo,
    required Widget destino,
    String? subtitulo,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRaios.grande),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => destino)),
      child: Container(
        height: AppTamanhos.alturaAtalho,
        padding: const EdgeInsets.all(AppEspacos.medio),
        decoration: BoxDecoration(
          color: fundo,
          borderRadius: BorderRadius.circular(AppRaios.grande),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          // spaceBetween: ícone no topo, texto embaixo.
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icone, size: 26, color: corIcone),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: estiloTitulo),
                if (subtitulo != null) Text(subtitulo, style: AppTextos.caixaSubtitulo),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _matchesRecentes(BuildContext context, DadosFicticios dados) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppEspacos.enorme),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Matches Recentes', style: AppTextos.secao),
            GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const EmBreveScreen(
                    aba: Aba.trocas,
                    titulo: 'Trocas',
                    icone: Icons.forum_outlined,
                    descricao: 'Encontre quem tem as figurinhas que faltam para você.',
                  ),
                ),
              ),
              child: Text('Ver todos', style: AppTextos.linkSecao),
            ),
          ],
        ),
        const SizedBox(height: AppEspacos.campo),
        // Lista que rola para o lado, como a .matches-list do site.
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final match in dados.matches) ...[
                _cardMatch(match),
                const SizedBox(width: AppEspacos.campo - 2),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _cardMatch(MatchFicticio match) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: AppEspacos.compacto + 3, horizontal: AppEspacos.campo - 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRaios.grande),
        border: Border.all(color: AppCores.borda),
      ),
      child: Column(
        children: [
          Container(
            width: AppTamanhos.avatarMatch,
            height: AppTamanhos.avatarMatch,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppCores.primariaClara,
              border: Border.all(color: AppCores.atalho, width: 2),
            ),
            child: Center(
              // Inicial do nome no lugar da foto.
              child: Text(match.nome.substring(0, 1), style: AppTextos.progressoPct),
            ),
          ),
          const SizedBox(height: AppEspacos.pequeno),
          Text(match.nome, style: AppTextos.matchNome),
          const SizedBox(height: AppEspacos.minimo),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppEspacos.pequeno, vertical: 3),
            decoration: BoxDecoration(
              color: AppCores.azulSuave,
              borderRadius: BorderRadius.circular(AppRaios.medio),
            ),
            child: Text('${match.mensagens} msgs', style: AppTextos.matchContagem),
          ),
        ],
      ),
    );
  }
}
