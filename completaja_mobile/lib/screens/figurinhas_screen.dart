import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../core/config.dart';
import '../core/theme.dart';
import '../models/figurinha.dart';
import '../models/resumo_figurinhas.dart';
import '../services/album_service.dart';
import '../widgets/aviso.dart';
import '../widgets/card_figurinha.dart';
import '../widgets/carrega_dados.dart';
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
  // Cópia local da grade: é ela que a tela desenha, e que muda na hora ao editar uma figurinha.
  ResumoFigurinhas? _resumo;
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
    return TelaPadrao(
      aba: Aba.albuns,
      corpo: CarregaDados<ResumoFigurinhas>(
        carregar: () async => _resumo = await context.read<AlbumService>().figurinhas(widget.albumId),
        construir: (context, _) => _conteudo(_resumo!),
      ),
    );
  }

  // Controle de edições seguidas na MESMA figurinha (cada código tem o seu):
  // `_confirmadas` guarda o último valor que o banco aceitou (para onde voltar se falhar),
  // `_fila` garante que as gravações saiam na ordem em que o usuário fez,
  // e `_ultimaEdicao` diz qual é a mais recente (só ela mexe na tela ao terminar).
  final Map<String, Figurinha> _confirmadas = {};
  final Map<String, Future<void>> _fila = {};
  final Map<String, int> _ultimaEdicao = {};

  /// Atualização otimista: a tela muda na hora e a API é chamada em seguida.
  /// Se a API falhar, a figurinha volta ao último valor confirmado e o usuário é avisado.
  Future<void> _salvar(Figurinha antiga, int quantidade, String nome) {
    final codigo = antiga.codigo;
    _confirmadas.putIfAbsent(codigo, () => antiga);
    final minhaVez = (_ultimaEdicao[codigo] ?? 0) + 1;
    _ultimaEdicao[codigo] = minhaVez;

    // O servidor não apaga o nome com texto vazio (regra do site); a tela segue a mesma regra.
    final nomeFinal = nome.isEmpty ? antiga.nome : nome;
    setState(() => _resumo = _resumo!.comFigurinha(
          Figurinha(codigo: codigo, nome: nomeFinal, quantidade: quantidade),
        ));

    // Espera a gravação anterior desta figurinha terminar, para o banco receber na ordem certa.
    final envio = (_fila[codigo] ?? Future<void>.value()).then((_) => _enviar(codigo, quantidade, nome, minhaVez));
    _fila[codigo] = envio;
    return envio;
  }

  Future<void> _enviar(String codigo, int quantidade, String nome, int minhaVez) async {
    final servico = context.read<AlbumService>();
    bool ehAMaisRecente() => minhaVez == _ultimaEdicao[codigo];

    try {
      final salva = await servico.salvarFigurinha(widget.albumId, codigo, quantidade: quantidade, nome: nome);
      _confirmadas[codigo] = salva; // o banco é a fonte da verdade
      if (mounted && ehAMaisRecente()) setState(() => _resumo = _resumo!.comFigurinha(salva));
    } on ApiException catch (e) {
      if (!mounted) return;
      // Se já existe uma edição mais nova, ela vai sobrescrever; só voltamos se esta for a última.
      if (ehAMaisRecente()) setState(() => _resumo = _resumo!.comFigurinha(_confirmadas[codigo]!));
      mostrarAviso(context, 'Não foi possível salvar a figurinha $codigo: ${e.mensagem}');
    }
  }

  Widget _conteudo(ResumoFigurinhas resumo) {
    final visiveis = _filtrar(resumo.figurinhas);

    // CustomScrollView + slivers: o cabeçalho e a grade rolam juntos, e a grade
    // (SliverGrid.builder) só constrói as figurinhas que aparecem na tela.
    return CustomScrollView(
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
                  itemBuilder: (context, i) => CardFigurinha(
                    figurinha: visiveis[i],
                    aoSalvar: (quantidade, nome) => _salvar(visiveis[i], quantidade, nome),
                  ),
                ),
        ),
      ],
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
                child: Image.network(
                  AppConfig.urlImagem(resumo.album.capaUrl) ?? '',
                  width: AppTamanhos.capaCabecalho,
                  fit: BoxFit.cover,
                  // Sem capa ou imagem quebrada: quadrado cinza com ícone.
                  errorBuilder: (_, _, _) => Container(
                    width: AppTamanhos.capaCabecalho,
                    height: AppTamanhos.capaCabecalho,
                    color: AppCores.campo,
                    child: const Icon(Icons.menu_book, color: AppCores.textoDesabilitado),
                  ),
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
