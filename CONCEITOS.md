# Conceitos de Dart e Flutter usados no app

Glossário para estudar depois do prazo. Cada item diz o que é e onde aparece no código.

## Etapa 2: casca do app (tema, abas, "Em breve")

### Dart
- **`import`**: traz código de outro arquivo ou pacote. `package:flutter/...` vem do Flutter; `'../core/theme.dart'` é um arquivo nosso (caminho relativo). Em todos os arquivos.
- **`const`**: valor criado em tempo de compilação e reaproveitado, sem recriar a cada redesenho. Por isso aparece tanto antes de widgets (`const Text(...)`). Em todas as telas.
- **`final`**: variável que recebe valor uma vez e não muda mais. Ex.: `final tema = Theme.of(context);` em `mensagem_central.dart`.
- **`static const` em classe com construtor privado (`AppCores._()`)**: jeito comum de agrupar constantes sob um nome (`AppCores.primaria`) sem permitir criar objetos daquela classe. Usado em `core/theme.dart`.
- **Parâmetros nomeados `{required this.titulo}`**: na hora de usar, escreve-se o nome (`titulo: 'Locais'`), o que deixa a chamada legível; `required` torna obrigatório. Usado em `em_breve_screen.dart`.
- **Tipo com `?` (`Widget? acao`)**: o valor pode ser `null` (opcional). O `!` em `acao!` diz "aqui eu garanto que não é null". Em `mensagem_central.dart`.
- **`if` e `...` dentro de lista**: adicionam itens à lista só quando a condição é verdadeira (`if (acao != null) ...[ ... ]`). Em `mensagem_central.dart`.
- **`=>` (arrow function)**: atalho para função de uma linha só que retorna o valor. Ex.: `onDestinationSelected: (indice) => setState(...)` em `app_shell.dart`.
- **`_` no início do nome (`_abaAtual`, `_AppShellState`)**: torna aquilo privado ao arquivo. Em `app_shell.dart`.

### Flutter
- **Widget**: tudo na tela é um widget (texto, botão, espaçamento, a tela inteira). Telas são widgets compostos de widgets menores.
- **`StatelessWidget`**: widget sem estado próprio, que só desenha o que recebe. Ex.: `EmBreveScreen`, `MensagemCentral`.
- **`StatefulWidget` + `State` + `setState`**: widget com dados que mudam. Alterar o dado dentro de `setState(() { ... })` faz o Flutter redesenhar. Ex.: `AppShell`, que guarda qual aba está selecionada.
- **`build(BuildContext context)`**: método que descreve o que desenhar. O Flutter chama de novo sempre que algo muda. O `context` dá acesso a coisas "de cima", como o tema.
- **`MaterialApp`**: raiz do app; define título, tema e primeira tela. Em `main.dart`.
- **`ThemeData` / `ColorScheme.fromSeed`**: o tema global. `fromSeed` gera uma paleta inteira a partir de uma cor. Em `core/theme.dart`.
- **`Theme.of(context)`**: lê o tema atual de dentro de qualquer widget, assim as telas não fixam cores. Em `mensagem_central.dart`.
- **`Scaffold` + `AppBar`**: estrutura padrão de uma tela (barra de título em cima, corpo, barra inferior). Em todas as telas.
- **`NavigationBar` + `NavigationDestination`**: barra inferior de abas do Material 3. Em `app_shell.dart`.
- **`IndexedStack`**: empilha várias telas e mostra só a do índice atual, mantendo o estado das outras vivo. Em `app_shell.dart`.
- **`Center`, `Column`, `Padding`, `SizedBox`**: layout básico: centralizar, empilhar na vertical, dar margem interna, criar espaço fixo entre itens. Em `mensagem_central.dart`.
- **Teste de widget (`testWidgets`, `pumpWidget`, `tap`, `pumpAndSettle`, `find`)**: monta o app num "celular de mentira", toca em coisas e confere o que aparece. Rodar com `flutter test`. Em `test/widget_test.dart`.
