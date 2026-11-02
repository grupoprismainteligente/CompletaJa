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

## Etapa 2b: UI idêntica ao site com dados fictícios

### Dart
- **`enum`**: lista fechada de opções (`Aba`, `_Filtro`). Evita "strings mágicas". Em `tela_padrao.dart` e `figurinhas_screen.dart`.
- **`switch` como expressão**: devolve um valor conforme o caso (`switch (destino) { Aba.home => ... }`). Em `tela_padrao.dart`.
- **Singleton (`static final instancia`)**: um único objeto compartilhado por todo o app. Usado em `services/dados_ficticios.dart`.
- **`late final`**: campo calculado uma vez, logo depois do construtor. Em `models/resumo_figurinhas.dart`.
- **Getter (`get faltante`)**: propriedade calculada na hora. Em `models/figurinha.dart`.
- **`Random(semente)`**: sorteio repetível; mesma semente, mesmos números. Gera as figurinhas fictícias.

### Flutter
- **`ChangeNotifier` + `ListenableBuilder`**: o dado avisa (`notifyListeners`) e a tela escuta e se redesenha. Usado ao adicionar um álbum (`dados_ficticios.dart`, `meus_albuns_screen.dart`).
- **`Navigator.push / pushReplacement / pop`**: empilha, troca ou fecha telas. Barra inferior e cards.
- **`SafeArea`**: evita que o conteúdo fique sob a barra de status. Em `tela_padrao.dart`.
- **`ListView`**: lista que rola. Em Meus Álbuns e Catálogo.
- **`CustomScrollView` + `SliverGrid.builder`**: rola cabeçalho e grade juntos e constrói só os itens visíveis. Em `figurinhas_screen.dart`.
- **`SliverGridDelegateWithMaxCrossAxisExtent`**: grade que decide quantas colunas cabem (o "auto-fill" do CSS).
- **`Stack` + `Positioned`**: sobrepõe widgets (selo "+N" no canto da figurinha). Em `card_figurinha.dart`.
- **`showDialog` / `AlertDialog`**: janela de confirmação ou detalhe. Sair, vincular álbum, detalhe da figurinha.
- **`TextEditingController`**: lê/controla um campo de texto; precisa de `dispose()`. Em `login_screen.dart`.
- **`InkWell` / `GestureDetector`**: tornam qualquer widget clicável.
- **`Image.asset` + `errorBuilder`**: imagem embutida no app, com plano B se falhar. Em `card_album.dart`.
- **`google_fonts`**: baixa a fonte Inter (a do site). Em `core/theme.dart`.
- **`PageTransitionsTheme` + `PageTransitionsBuilder`**: define no tema como toda troca de tela é animada; `transitionDuration` zero = troca instantânea, com a tela já montada. Em `core/theme.dart` (`_TrocaInstantanea`).

## Etapa 3: login real (rede, sessão e estado)

### Dart
- **`async` / `await` / `Future`**: uma chamada de rede demora; `Future` é o "resultado que chega depois" e `await` espera sem travar a tela. Em `api_client.dart` e `auth_service.dart`.
- **`try` / `on` / `catch` / `finally`**: trata erros por tipo (`on ApiException`, `on SocketException`); `finally` roda sempre, dando certo ou não (usado para desligar o "carregando"). Em `login_screen.dart` e `api_client.dart`.
- **`throw` e classe de exceção própria (`ApiException implements Exception`)**: cria um erro com mensagem pronta para a tela mostrar. Em `core/api_client.dart`.
- **`fromJson` / `toJson` (factory constructor)**: transforma o JSON da API em objeto Dart e de volta. Em `models/usuario.dart`.
- **`String.fromEnvironment` e `--dart-define`**: lê um valor passado na hora de compilar (`flutter run --dart-define=AMBIENTE=producao`); assim a URL do servidor muda sem editar código. Em `core/config.dart`.
- **Record `({String? token, String? usuario})`**: devolve dois valores juntos sem criar uma classe. Em `ArmazenamentoSessao.ler()`.
- **`switch` como expressão**: escolhe um valor conforme o caso (`EstadoSessao.logado => const HomeScreen()`). Em `main.dart`.
- **`abstract class` + `implements`**: define um "contrato"; o app usa a versão real (`ArmazenamentoSeguro`) e os testes usam uma de mentira em memória. Em `services/auth_service.dart`.
- **`enum`**: lista fechada de opções (`EstadoSessao`: iniciando, deslogado, logado).
- **`Timer`**: executa algo depois de um tempo (avisar "acordando o servidor" após 5 s). Em `login_screen.dart`.

### Flutter
- **`ChangeNotifier` + `notifyListeners()`**: objeto que avisa quem o escuta quando muda. Em `AuthService`.
- **`provider` (`ChangeNotifierProvider`, `context.read`, `context.watch`)**: entrega um objeto (o `AuthService`) para qualquer tela abaixo. `watch` redesenha quando ele muda; `read` só pega, sem redesenhar. Em `main.dart`, `login_screen.dart`, `tela_padrao.dart`.
- **`flutter_secure_storage`**: guarda o token criptografado no celular (Keystore do Android), para entrar direto na próxima abertura. Em `services/auth_service.dart`.
- **`http` e `MockClient`**: o pacote `http` faz as chamadas; nos testes o `MockClient` finge ser o servidor. Em `core/api_client.dart` e `test/widget_test.dart`.
- **`GlobalKey<NavigatorState>` + `pushAndRemoveUntil`**: navega sem ter um `context` de tela e apaga toda a pilha de telas; usado para voltar ao login de qualquer lugar quando a sessão cai. Em `main.dart` (`_OuvinteDeSessao`).
- **`MaterialApp.builder`**: coloca um widget "por cima" de todas as telas (aqui, o que escuta a sessão). Em `main.dart`.
- **`StatefulWidget` com `initState` / `dispose`**: guarda estado e registra/remove ouvintes (`addListener` / `removeListener`). Em `main.dart`.
- **`mounted`**: depois de um `await` a tela pode já ter saído; conferir `mounted` evita usar uma tela que não existe mais. Em `login_screen.dart`.
- **`CircularProgressIndicator`**: a "bolinha girando" do carregando. Em `login_screen.dart` e `widgets/carregando.dart`.
- **`Image.network` + `ClipOval` + `errorBuilder`**: imagem da internet recortada em círculo, com plano B se a rede ou o link falharem. Em `tela_padrao.dart` (foto do usuário).
- **`network_security_config` (Android)**: o Android bloqueia HTTP puro por padrão; um arquivo só do build debug libera, para o emulador falar com o servidor local. Em `android/app/src/debug/res/xml/`.
- **`uses-permission INTERNET` (AndroidManifest)**: sem ela o APK instalado não acessa a internet. Em `android/app/src/main/AndroidManifest.xml`.
- **`Future` + `FutureBuilder`**: um `Future` é um resultado que chega depois (a resposta da API); o `FutureBuilder` desenha "carregando", "erro" ou "pronto" conforme ele anda. Em `widgets/carrega_dados.dart`.
- **Widget genérico (`CarregaDados<T>`)**: o `<T>` deixa o mesmo widget servir para qualquer tipo de dado (lista de álbuns, resumo da Home...). Usado em todas as telas que leem da API.
- **`GlobalKey<...State>`**: chave que dá acesso ao estado de um widget filho; em `meus_albuns_screen.dart` serve para mandar recarregar a lista ao voltar do catálogo.
- **`Timer` + `dispose`**: um `Timer` precisa ser cancelado no `dispose`, senão continua rodando depois que a tela sai. Em `widgets/carrega_dados.dart` (aviso "acordando o servidor").
- **`MultiProvider` e `Provider` simples**: entrega vários objetos de uma vez; `Provider` (sem `ChangeNotifier`) serve para objetos que não avisam mudanças, como o `AlbumService`. Em `main.dart`.
- **`fromJson` (factory)**: transforma o JSON da API em objeto Dart. Em `models/*.dart`.
- **Atualização otimista**: a tela muda na hora e a API é chamada depois; se falhar, a tela volta ao estado anterior e avisa. Em `figurinhas_screen.dart` (`_salvar`).
- **`showDialog<T>` que devolve valor + record `({int quantidade, String nome})`**: o diálogo fecha com `Navigator.pop(context, valor)` e quem abriu recebe o resultado no `await`. Em `widgets/card_figurinha.dart`.
- **`TextEditingController` + `dispose`**: lê/define o texto de um `TextField`; precisa ser descartado no `dispose`. Em `_EditorFigurinha`.
- **`clamp`**: limita um número a um intervalo (quantidade entre 0 e 99). Em `_EditorFigurinha`.
