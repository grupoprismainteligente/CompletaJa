import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:completaja_mobile/main.dart';

void main() {
  // Nos testes não há internet; sem isso o google_fonts tentaria baixar a Inter.
  GoogleFonts.config.allowRuntimeFetching = false;

  // No teste a fonte é a "Ahem" (cada letra é um quadrado largo), então textos
  // estouram a largura só aqui. Ignoramos apenas esse aviso; o resto continua falhando.

  testWidgets('login leva à Home e dá para navegar por álbuns e figurinhas', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    // O testWidgets instala o próprio tratador de erros, então o nosso entra aqui dentro.
    final tratadorOriginal = FlutterError.onError;
    FlutterError.onError = (detalhes) {
      if (detalhes.exceptionAsString().contains('overflowed')) return;
      tratadorOriginal?.call(detalhes);
    };

    await tester.pumpWidget(const CompletaJaApp());
    expect(find.text('Complete seu álbum com amigos!'), findsOneWidget);

    // Login vazio mostra erro; preenchido entra na Home.
    await tester.tap(find.text('Entrar').last);
    await tester.pump();
    expect(find.text('Informe e-mail e senha.'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'igor@teste.com');
    await tester.enterText(find.byType(TextField).last, '123');
    await tester.tap(find.text('Entrar').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('Olá,'), findsOneWidget);
    expect(find.text('REPETIDAS'), findsOneWidget);

    // Aba Álbuns -> abre um álbum.
    await tester.tap(find.text('Álbuns'));
    await tester.pumpAndSettle();
    expect(find.text('Meus Álbuns'), findsOneWidget);
    await tester.tap(find.text('Copa do Mundo 2026'));
    await tester.pumpAndSettle();
    expect(find.text('Progresso Total'), findsOneWidget);

    // Abas Locais/Trocas mostram "em breve".
    await tester.tap(find.text('Locais'));
    await tester.pumpAndSettle();
    expect(find.text('Locais: em breve'), findsOneWidget);
  });
}
