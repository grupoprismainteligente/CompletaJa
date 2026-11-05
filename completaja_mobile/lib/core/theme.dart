import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// =============================================================================
// IDENTIDADE VISUAL DO APP
//
// REGRA: nenhuma tela escolhe cor, fonte, raio de borda ou espaçamento por conta
// própria. Tudo sai daqui. Trocar a identidade do app = editar só este arquivo.
//
// Por enquanto este tema REPRODUZ o visual do site (azul, fonte Inter, cantos
// arredondados), a pedido do usuário, para o app ficar idêntico ao MVC.
// Os valores foram copiados de wwwroot/css/*.css do projeto web.
// =============================================================================

/// Paleta. As telas usam estes nomes, nunca `Color(0xFF...)` direto.
class AppCores {
  AppCores._(); // impede criar instâncias; a classe é só um "agrupador" de constantes

  // Azuis
  static const Color primaria = Color(0xFF1D58E6); // logo, títulos, botões
  static const Color primariaEscura = Color(0xFF004EEB); // botão "Entrar"
  static const Color atalho = Color(0xFF2563EB); // card "Meus Álbuns" da Home
  static const Color primariaClara = Color(0xFFE6EFFF); // fundo de cards/botões +/-
  static const Color azulSuave = Color(0xFFDBEAFE); // chips e caixa "Encontrar Trocas"
  static const Color azulBadge = Color(0xFFEFF6FF); // badge "N figurinhas"
  static const Color azulEscuro = Color(0xFF1E3A8A);
  static const Color azulTextoAtalho = Color(0xFFBFDBFE);

  // Fundos
  static const Color fundoPagina = Color(0xFFF8F9FE);
  static const Color superficie = Color(0xFFFFFFFF);
  static const Color campo = Color(0xFFF3F4F6); // fundo dos inputs do login
  static const Color alternador = Color(0xFFEEF2FA); // fundo do Entrar/Criar Conta

  // Textos
  static const Color texto = Color(0xFF111827);
  static const Color textoTitulo = Color(0xFF0F172A);
  static const Color textoSuave = Color(0xFF6B7280);
  static const Color textoMuted = Color(0xFF64748B);
  static const Color textoDesabilitado = Color(0xFF9CA3AF);

  // Bordas
  static const Color borda = Color(0xFFE5E7EB);
  static const Color bordaSuave = Color(0xFFF3F4F6);
  static const Color bordaCard = Color(0xFFF1F5F9);
  static const Color bordaCampo = Color(0xFFCBD5E1);
  static const Color trilhaProgresso = Color(0xFFE2E8F0);

  // Estados das figurinhas
  static const Color colada = Color(0xFF22C55E);
  static const Color coladaFundo = Color(0xFFF0FDF4);
  static const Color coladaTexto = Color(0xFF166534);
  static const Color repetida = Color(0xFFFBBF24); // dourado
  static const Color repetidaTexto = Color(0xFF78350F);
  static const Color faltante = Color(0xFFD1D5DB);
  static const Color faltantesTexto = Color(0xFFD97706);

  // Alertas
  static const Color erro = Color(0xFFDC2626);
  static const Color erroFundo = Color(0xFFFEE2E2);
  static const Color sucessoFundo = Color(0xFFDCFCE7);
  static const Color sucessoTexto = Color(0xFF15803D);
}

/// Espaçamentos (padding, margens, distância entre itens).
class AppEspacos {
  AppEspacos._();

  static const double minimo = 4;
  static const double pequeno = 8;
  static const double campo = 10;
  static const double compacto = 12;
  static const double medio = 16;
  static const double grande = 24;
  static const double enorme = 32;

  /// Margem lateral padrão das telas (`padding: 0 20px` do site).
  static const double lateral = 20;
}

/// Raios de borda (cantos arredondados).
class AppRaios {
  AppRaios._();

  static const double pequeno = 8;
  static const double campo = 10;
  static const double medio = 12;
  static const double grande = 16;
  static const double card = 20;
  static const double painel = 24;
  static const double pilula = 100;
}

/// Tamanhos que se repetem.
class AppTamanhos {
  AppTamanhos._();

  static const double iconeDestaque = 64;
  static const double avatarTopo = 40;
  static const double avatarMatch = 50;
  static const double capaLista = 120;
  static const double capaCabecalho = 140;
  static const double alturaCampo = 48;
  static const double alturaBotao = 50;
  static const double alturaProgresso = 12;
  static const double alturaCardFigurinha = 130;
  static const double larguraMaximaFigurinha = 130;
  static const double alturaAtalho = 110;
}

/// Estilos de texto. Fonte Inter (a mesma do site), baixada pelo google_fonts.
class AppTextos {
  AppTextos._();

  static TextStyle _inter(double tamanho, FontWeight peso, Color cor, {double? altura, double? espacamento}) {
    return GoogleFonts.inter(
      fontSize: tamanho,
      fontWeight: peso,
      color: cor,
      height: altura,
      letterSpacing: espacamento,
    );
  }

  // Cabeçalho global
  static final TextStyle logo = _inter(18, FontWeight.w700, AppCores.primaria);
  static final TextStyle sair = _inter(13, FontWeight.w600, AppCores.textoSuave);
  static final TextStyle navegacao = _inter(10, FontWeight.w600, AppCores.textoDesabilitado);

  // Login
  static final TextStyle loginTitulo = _inter(28, FontWeight.w700, AppCores.primaria);
  static final TextStyle loginSubtitulo = _inter(14, FontWeight.w400, AppCores.textoSuave);
  static final TextStyle rotuloCampo = _inter(12, FontWeight.w600, AppCores.texto);
  static final TextStyle campoEntrada = _inter(14, FontWeight.w400, const Color(0xFF374151));
  static final TextStyle dicaCampo = _inter(14, FontWeight.w400, AppCores.textoDesabilitado);
  static final TextStyle botaoLogin = _inter(16, FontWeight.w600, AppCores.superficie);
  static final TextStyle alternadorTexto = _inter(14, FontWeight.w600, AppCores.textoSuave);
  static final TextStyle alternadorAtivo = _inter(14, FontWeight.w600, AppCores.primaria);
  static final TextStyle linkPequeno = _inter(12, FontWeight.w600, AppCores.primaria);
  static final TextStyle rodapeLogin = _inter(12, FontWeight.w400, AppCores.textoSuave, altura: 1.5);
  static final TextStyle alertaErro = _inter(14, FontWeight.w600, AppCores.erro);

  // Home
  static final TextStyle boasVindas = _inter(32, FontWeight.w800, AppCores.primaria, altura: 1.2);
  static final TextStyle estatisticaNumero = _inter(36, FontWeight.w800, AppCores.primaria);
  static final TextStyle estatisticaRotulo =
      _inter(10, FontWeight.w700, AppCores.textoSuave, espacamento: 0.5);
  static final TextStyle secao = _inter(16, FontWeight.w700, AppCores.texto);
  static final TextStyle linkSecao = _inter(13, FontWeight.w600, AppCores.atalho);
  static final TextStyle atalhoTitulo = _inter(18, FontWeight.w700, AppCores.superficie);
  static final TextStyle atalhoSubtitulo = _inter(12, FontWeight.w400, AppCores.azulTextoAtalho);
  static final TextStyle caixaTitulo = _inter(14, FontWeight.w700, AppCores.repetidaTexto);
  static final TextStyle caixaTituloAzul = _inter(14, FontWeight.w700, AppCores.azulEscuro);
  static final TextStyle caixaSubtitulo = _inter(10, FontWeight.w400, AppCores.azulEscuro);
  static final TextStyle matchNome = _inter(13, FontWeight.w700, AppCores.texto);
  static final TextStyle matchContagem = _inter(10, FontWeight.w600, AppCores.atalho);
  static final TextStyle vazioTexto = _inter(14, FontWeight.w400, const Color(0xFF94A3B8), altura: 1.4);

  // Listas (Meus Álbuns / Catálogo)
  static final TextStyle paginaTitulo = _inter(29, FontWeight.w800, AppCores.textoTitulo);
  static final TextStyle paginaSubtitulo = _inter(15, FontWeight.w400, AppCores.textoMuted);
  static final TextStyle botaoPrimario = _inter(16, FontWeight.w700, AppCores.superficie);
  static final TextStyle campoBusca = _inter(15, FontWeight.w400, AppCores.texto);
  static final TextStyle dicaBusca = _inter(15, FontWeight.w400, const Color(0xFF94A3B8));
  static final TextStyle cardTitulo = _inter(18, FontWeight.w800, AppCores.textoTitulo, altura: 1.2);
  static final TextStyle badgeLista = _inter(12, FontWeight.w700, AppCores.primaria);
  static final TextStyle cardDetalhe = _inter(14, FontWeight.w400, AppCores.textoMuted);
  static final TextStyle cardDestaque = _inter(13, FontWeight.w700, AppCores.primaria);
  static final TextStyle badgeJaColeciona = _inter(12, FontWeight.w700, AppCores.sucessoTexto);
  static final TextStyle criarNovoTitulo = _inter(17, FontWeight.w700, AppCores.primaria);
  static final TextStyle criarNovoTexto = _inter(13, FontWeight.w400, AppCores.textoMuted);

  // Figurinhas
  static final TextStyle albumTitulo = _inter(29, FontWeight.w800, AppCores.textoTitulo, altura: 1.2);
  static final TextStyle progressoRotulo = _inter(14, FontWeight.w600, const Color(0xFF475569));
  static final TextStyle progressoPct = _inter(24, FontWeight.w800, AppCores.primaria);
  static final TextStyle progressoRodape = _inter(13, FontWeight.w600, AppCores.textoMuted);
  static final TextStyle progressoFaltantes = _inter(13, FontWeight.w600, AppCores.faltantesTexto);
  static final TextStyle filtro = _inter(14, FontWeight.w600, const Color(0xFF475569));
  static final TextStyle figNumero = _inter(18, FontWeight.w800, AppCores.texto, altura: 1.1);
  static final TextStyle figNumeroColada = _inter(18, FontWeight.w800, AppCores.coladaTexto, altura: 1.1);
  static final TextStyle figNome = _inter(10, FontWeight.w700, AppCores.textoSuave);
  static final TextStyle figBadge = _inter(12, FontWeight.w800, AppCores.superficie);
  static final TextStyle figBadgeExtra = _inter(12, FontWeight.w800, AppCores.repetidaTexto);

  // Janela de detalhe da figurinha
  static final TextStyle modalTitulo = _inter(19, FontWeight.w700, AppCores.texto);
  static final TextStyle modalNumero = _inter(19, FontWeight.w700, AppCores.primaria);
  static final TextStyle modalRotulo = _inter(13, FontWeight.w600, AppCores.textoSuave);
  static final TextStyle modalQuantidade = _inter(24, FontWeight.w700, AppCores.texto);
  static final TextStyle modalValor = _inter(16, FontWeight.w400, AppCores.texto);

  // Em breve
  static final TextStyle emBreveTitulo = _inter(24, FontWeight.w800, AppCores.textoTitulo);
  static final TextStyle emBreveTexto = _inter(14, FontWeight.w400, AppCores.textoMuted, altura: 1.4);
}

/// Sombras que se repetem.
class AppSombras {
  AppSombras._();

  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x05000000), blurRadius: 15, offset: Offset(0, 4)),
  ];
  static const List<BoxShadow> painel = [
    BoxShadow(color: Color(0x0D000000), blurRadius: 20, offset: Offset(0, 4)),
  ];
  static const List<BoxShadow> capa = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 10, offset: Offset(0, 4)),
  ];
}

class AppTheme {
  AppTheme._();

  static ThemeData get claro {
    final cores = ColorScheme.fromSeed(
      seedColor: AppCores.primaria,
      primary: AppCores.primaria,
      surface: AppCores.superficie,
      onSurface: AppCores.texto,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cores,
      scaffoldBackgroundColor: AppCores.superficie,
      dialogTheme: DialogThemeData(
        backgroundColor: AppCores.superficie,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRaios.card)),
      ),
      // Vale para todo MaterialPageRoute do app, em qualquer plataforma.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _TrocaInstantanea(),
          TargetPlatform.iOS: _TrocaInstantanea(),
          TargetPlatform.windows: _TrocaInstantanea(),
          TargetPlatform.macOS: _TrocaInstantanea(),
          TargetPlatform.linux: _TrocaInstantanea(),
          TargetPlatform.fuchsia: _TrocaInstantanea(),
        },
      ),
    );
  }
}

/// Troca de tela sem animação. A transição padrão desliza/afunda a tela nova
/// por cima da antiga, e por alguns quadros as duas aparecem misturadas. Com
/// duração zero a tela nova só é mostrada já montada, e ao voltar a anterior
/// reaparece na hora.
class _TrocaInstantanea extends PageTransitionsBuilder {
  const _TrocaInstantanea();

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}
