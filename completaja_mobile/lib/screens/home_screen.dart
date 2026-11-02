import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../models/resumo_home.dart';
import '../services/album_service.dart';
import '../services/auth_service.dart';
import '../widgets/carrega_dados.dart';
import '../widgets/tela_padrao.dart';
import 'em_breve_screen.dart';
import 'meus_albuns_screen.dart';

/// Home: saudação, contadores de repetidas/faltantes, atalhos e matches recentes.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TelaPadrao(
      aba: Aba.home,
      // Os contadores vêm da API; a Home é recriada ao trocar de aba, então busca de novo.
      corpo: CarregaDados<ResumoHome>(
        carregar: context.read<AlbumService>().home,
        construir: (context, resumo) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppEspacos.lateral),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppEspacos.lateral),
              Text('Olá,\n${context.watch<AuthService>().usuario?.nome ?? ''}!', style: AppTextos.boasVindas),
              const SizedBox(height: AppEspacos.enorme),
              _estatisticas(resumo),
              const SizedBox(height: AppEspacos.enorme),
              Text('Atalhos', style: AppTextos.secao),
              const SizedBox(height: AppEspacos.medio),
              _atalhoPrincipal(context),
              const SizedBox(height: AppEspacos.medio),
              _atalhosSecundarios(context),
              _matchesRecentes(context),
              const SizedBox(height: AppEspacos.grande),
            ],
          ),
        ),
      ),
    );
  }

  Widget _estatisticas(ResumoHome dados) {
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

  Widget _matchesRecentes(BuildContext context) {
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
        // Trocas e matches são da V2 (ainda não existem na API): sem dado real, sem card de mentira.
        Text('Seus matches aparecerão aqui quando as trocas chegarem ao app.', style: AppTextos.vazioTexto),
      ],
    );
  }
}
