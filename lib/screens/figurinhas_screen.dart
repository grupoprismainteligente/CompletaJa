import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/figurinha.dart';
import '../models/resumo_figurinhas.dart';
import '../services/dados_ficticios.dart';
import '../widgets/card_figurinha.dart';
import '../widgets/tela_padrao.dart';

/// Figurinhas de um álbum: cabeçalho com progresso, busca por número,
/// filtro Todas/Faltantes/Repetidas e a grade 1..N. Somente consulta.
class FigurinhasScreen extends StatefulWidget {
  const FigurinhasScreen({super.key, required this.albumId});

  final int albumId;

  @override
  State<FigurinhasScreen> createState() => _FigurinhasScreenState();
}

enum _Filtro { todas, faltantes, repetidas }

class _FigurinhasScreenState extends State<FigurinhasScreen> {
  String _busca = '';
  _Filtro _filtro = _Filtro.todas;

  List<Figurinha> _filtrar(List<Figurinha> todas) {
    return todas.where((f) {
      if (_busca.isNotEmpty && !f.codigo.contains(_busca.trim())) return false;
      return switch (_filtro) {
        _Filtro.todas => true,
        _Filtro.faltantes => f.faltante,
        _Filtro.repetidas => f.repetida,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final resumo = DadosFicticios.instancia.figurinhasDoAlbum(widget.albumId);
    final visiveis = _filtrar(resumo.figurinhas);

    return TelaPadrao(
      aba: Aba.albuns,
      // CustomScrollView + slivers: o cabeçalho e a grade rolam juntos, e a grade
      // (SliverGrid.builder) só constrói as figurinhas que aparecem na tela.
      corpo: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppEspacos.lateral,
              AppEspacos.lateral,
              AppEspacos.lateral,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  _CabecalhoAlbum(resumo: resumo),
                  const SizedBox(height: AppEspacos.lateral + 5),
                  _controles(),
                  const SizedBox(height: AppEspacos.lateral + 5),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppEspacos.lateral,
              0,
              AppEspacos.lateral,
              AppEspacos.enorme,
            ),
            sliver: visiveis.isEmpty
                ? SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(AppEspacos.grande),
                      child: Text(
                        'Nenhuma figurinha encontrada.',
                        style: AppTextos.vazioTexto,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : SliverGrid.builder(
                    // "Auto-fill" do CSS: quantas colunas couberem, cada uma com até 130 de largura.
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: AppTamanhos.larguraMaximaFigurinha,
                      mainAxisExtent: AppTamanhos.alturaCardFigurinha,
                      mainAxisSpacing: AppEspacos.compacto,
                      crossAxisSpacing: AppEspacos.compacto,
                    ),
                    itemCount: visiveis.length,
                    itemBuilder: (context, i) => CardFigurinha(figurinha: visiveis[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _controles() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            onChanged: (texto) => setState(() => _busca = texto),
            keyboardType: TextInputType.number,
            style: AppTextos.campoBusca,
            decoration: InputDecoration(
              hintText: 'Buscar por Número...',
              hintStyle: AppTextos.dicaBusca,
              prefixIcon: const Icon(Icons.search, color: AppCores.textoDesabilitado),
              contentPadding: const EdgeInsets.symmetric(vertical: AppEspacos.compacto),
              enabledBorder: _bordaCampo(AppCores.borda),
              focusedBorder: _bordaCampo(AppCores.primaria),
            ),
          ),
        ),
        const SizedBox(width: AppEspacos.campo),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppEspacos.medio - 1),
          decoration: BoxDecoration(
            color: AppCores.superficie,
            borderRadius: BorderRadius.circular(AppRaios.medio),
            border: Border.all(color: AppCores.borda),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<_Filtro>(
              value: _filtro,
              style: AppTextos.filtro,
              borderRadius: BorderRadius.circular(AppRaios.medio),
              items: const [
                DropdownMenuItem(value: _Filtro.todas, child: Text('Todas')),
                DropdownMenuItem(value: _Filtro.faltantes, child: Text('Faltantes')),
                DropdownMenuItem(value: _Filtro.repetidas, child: Text('Repetidas')),
              ],
              onChanged: (novo) => setState(() => _filtro = novo ?? _Filtro.todas),
            ),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _bordaCampo(Color cor) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRaios.medio),
        borderSide: BorderSide(color: cor),
      );
}

/// Cartão do topo: capa, nome do álbum e barra de progresso.
class _CabecalhoAlbum extends StatelessWidget {
  const _CabecalhoAlbum({required this.resumo});

  final ResumoFigurinhas resumo;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppEspacos.lateral),
      decoration: BoxDecoration(
        color: AppCores.superficie,
        borderRadius: BorderRadius.circular(AppRaios.card),
        border: Border.all(color: AppCores.bordaSuave),
        boxShadow: AppSombras.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRaios.campo),
                boxShadow: AppSombras.capa,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRaios.campo),
                child: Image.asset(
                  resumo.album.capa,
                  width: AppTamanhos.capaCabecalho,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppEspacos.medio),
          Text(resumo.album.nome, style: AppTextos.albumTitulo),
          const SizedBox(height: AppEspacos.lateral),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Progresso Total', style: AppTextos.progressoRotulo),
              Text('${resumo.progresso}%', style: AppTextos.progressoPct),
            ],
          ),
          const SizedBox(height: AppEspacos.pequeno),
          // Barra de progresso: trilha cinza com um preenchimento proporcional por cima.
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRaios.pequeno),
            child: LinearProgressIndicator(
              value: resumo.progresso / 100,
              minHeight: AppTamanhos.alturaProgresso,
              backgroundColor: AppCores.trilhaProgresso,
              valueColor: const AlwaysStoppedAnimation(AppCores.primaria),
            ),
          ),
          const SizedBox(height: AppEspacos.pequeno - 3),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${resumo.unicas} / ${resumo.total} figurinhas',
                style: AppTextos.progressoRodape,
              ),
              Text('${resumo.faltantes} faltantes', style: AppTextos.progressoFaltantes),
            ],
          ),
        ],
      ),
    );
  }
}
