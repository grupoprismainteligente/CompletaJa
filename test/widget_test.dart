import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:completaja_mobile/main.dart';

void main() {
  testWidgets('abre no Início e as abas Locais e Trocas mostram "Em breve"', (tester) async {
    await tester.pumpWidget(const CompletaJaApp());

    // Abre na aba Início.
    expect(find.text('Bem-vindo ao CompletaJá'), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(4));

    // Toca na aba Locais (pelo ícone, porque o texto "Locais" também vira título da tela).
    await tester.tap(find.byIcon(Icons.place_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Em breve'), findsOneWidget);
    expect(find.textContaining('Pontos seguros'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.swap_horiz));
    await tester.pumpAndSettle();
    expect(find.textContaining('Encontre quem tem'), findsOneWidget);
  });
}
