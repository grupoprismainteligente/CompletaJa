import 'package:flutter/material.dart';

import 'em_breve_screen.dart';
import 'home_screen.dart';
import 'meus_albuns_screen.dart';

/// "Casca" do app depois do login: a barra inferior com 4 abas e a tela da aba atual.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  // Índice da aba selecionada: 0 Início, 1 Álbuns, 2 Locais, 3 Trocas.
  int _abaAtual = 0;

  // As telas são criadas uma vez só. Com o IndexedStack, trocar de aba e voltar
  // mantém o estado de cada uma (rolagem, busca digitada, dados já carregados).
  static const List<Widget> _telas = [
    HomeScreen(),
    MeusAlbunsScreen(),
    EmBreveScreen(
      titulo: 'Locais',
      icone: Icons.place_outlined,
      descricao: 'Pontos seguros para encontrar outros colecionadores e trocar figurinhas.',
    ),
    EmBreveScreen(
      titulo: 'Trocas',
      icone: Icons.swap_horiz,
      descricao: 'Encontre quem tem as figurinhas que faltam para você.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _abaAtual, children: _telas),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _abaAtual,
        // setState avisa o Flutter que o estado mudou e a tela precisa ser redesenhada.
        onDestinationSelected: (indice) => setState(() => _abaAtual = indice),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.collections_bookmark_outlined),
            selectedIcon: Icon(Icons.collections_bookmark),
            label: 'Álbuns',
          ),
          NavigationDestination(
            icon: Icon(Icons.place_outlined),
            selectedIcon: Icon(Icons.place),
            label: 'Locais',
          ),
          NavigationDestination(
            icon: Icon(Icons.swap_horiz),
            label: 'Trocas',
          ),
        ],
      ),
    );
  }
}
