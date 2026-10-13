import 'package:flutter/material.dart';

// =============================================================================
// IDENTIDADE VISUAL DO APP
//
// REGRA: nenhuma tela escolhe cor, fonte, raio de borda ou espaçamento por conta
// própria. Tudo sai daqui. Trocar a identidade do app = editar só este arquivo.
//
// O tema abaixo é PROVISÓRIO e neutro de propósito (cinza-azulado + âmbar),
// só para o app ter cara de app enquanto a identidade definitiva não é escolhida.
// =============================================================================

/// Paleta base. As telas não usam estas cores direto: usam
/// `Theme.of(context).colorScheme`, que é montado a partir delas.
class AppCores {
  AppCores._(); // impede criar instâncias; a classe é só um "agrupador" de constantes

  static const Color primaria = Color(0xFF455A64);
  static const Color destaque = Color(0xFFFFB300);
  static const Color fundo = Color(0xFFF5F5F5);
  static const Color texto = Color(0xFF212121);
}

/// Espaçamentos (padding, margens, distância entre itens).
class AppEspacos {
  AppEspacos._();

  static const double pequeno = 8;
  static const double medio = 16;
  static const double grande = 24;
}

/// Raios de borda (cantos arredondados).
class AppRaios {
  AppRaios._();

  static const double pequeno = 8;
  static const double medio = 12;
}

/// Tamanhos que se repetem (ícones grandes de aviso, por exemplo).
class AppTamanhos {
  AppTamanhos._();

  static const double iconeDestaque = 64;
}

class AppTheme {
  AppTheme._();

  static ThemeData get claro {
    // fromSeed gera uma paleta completa e harmônica (tons para botões, fundos,
    // bordas...) a partir de uma cor; as demais sobrescrevem tons específicos.
    final cores = ColorScheme.fromSeed(
      seedColor: AppCores.primaria,
      primary: AppCores.primaria,
      secondary: AppCores.destaque,
      surface: AppCores.fundo,
      onSurface: AppCores.texto,
    );

    return ThemeData(
      colorScheme: cores,
      scaffoldBackgroundColor: cores.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: cores.surface,
        foregroundColor: cores.onSurface,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: cores.secondary,
      ),
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRaios.medio),
        ),
      ),
    );
  }
}
