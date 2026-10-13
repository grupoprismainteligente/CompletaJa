# CompletaJá Mobile

App Android em Flutter que é a versão "catálogo visual" do CompletaJá, um sistema web (ASP.NET Core MVC) para colecionar figurinhas de qualquer álbum e combinar trocas em locais seguros.

**Prazo:** app funcional até a primeira semana de novembro de 2026 (meta: 6/nov). Hoje é 13/out/2026.

## Sobre o usuário (leia antes de qualquer coisa)

- Está no último semestre de ADS. Sabe o básico de programação e **não entende o projeto web MVC**. Dart e Flutter são novos para ele.
- Vai "vibe codar" o app por causa do prazo e estudar depois. Isso foi decidido e não está em discussão. Não sugira parar para estudar nem refaça o plano.
- Mesmo assim, ele quer entender depois. Portanto:
  - Mantenha o arquivo `CONCEITOS.md` na raiz. A cada tela ou recurso novo, acrescente 1-2 linhas por conceito de Dart/Flutter usado (ex.: "`ListView.builder`: constrói itens sob demanda; usado em `meus_albuns_screen.dart`").
  - Comente o código de forma útil, em português, explicando o **porquê**, sem narrar o óbvio.
  - Prefira código simples e convencional a soluções "espertas".
- Responda em português do Brasil.

## Escopo da V1

**Dentro:**
1. Login (e-mail e senha) e logout. A criação de conta continua sendo feita no site.
2. Home: contadores de repetidas e faltantes, atalhos.
3. Meus Álbuns: lista com filtro por nome, estado vazio.
4. Catálogo de Álbuns: lista com busca, "adicionar à minha coleção".
5. Figurinhas de um álbum: cabeçalho com progresso, grade 1..N, busca por número, filtro Todas/Faltantes/Repetidas, editar quantidade e nome.
6. A barra inferior tem 4 abas (Home, Álbuns, Locais, Trocas). **Locais e Trocas mostram apenas "Em breve".**

**Fora (V2):** locais, trocas/matches, chat (SignalR), cadastro de conta, edição de perfil, recuperação de senha.

A coleção do usuário no app deve ser **exatamente a mesma do site**, porque os dois usam o mesmo banco.

## Como os dois projetos se relacionam

```
App Flutter  --HTTPS/JSON-->  API (nova, dentro do projeto web)  -->  SQL Server
Site MVC (já pronto) ----------------------------------------------^
```

- O app **nunca** fala com o banco. Só com a API.
- O site no Render: `https://completaja-prisma.onrender.com`. O plano é gratuito e **dorme quando fica parado**: a primeira chamada pode levar 30-60 s. O app precisa de timeout longo (>= 90 s) e de uma tela de carregamento com mensagem do tipo "acordando o servidor".
- Projeto web (C#): `C:\Users\igor0\source\repos\PIM-CompletaJa\CompletaJáApp` (o nome da pasta tem acento).
- Emulador Android acessa o servidor local do Visual Studio por `https://10.0.2.2:<porta>`. Deixe a URL base em um único lugar do app (`lib/core/config.dart`), com opção de produção e de desenvolvimento.

## O que existe hoje no projeto web (resumo verificado)

ASP.NET Core MVC, EF Core + SQL Server, sessão em memória, SignalR para chat. **Não existe API.** Todos os Controllers devolvem `View()` e autenticam por sessão (`HttpContext.Session`).

Tabelas (namespace `CompletaJaApp.Models`):
- `Usuario`: Id, Nome, Email, SenhaHash, CPF, FotoUrl
- `Album`: Id, Nome, QuantidadeTotalFigurinhas (coluna `TotalFigurinhas`), CapaUrl, UsuariosVinculados
- `UsuarioAlbum`: Id, UsuarioId, AlbumId (quais álbuns o usuário coleciona)
- `Figurinha`: Id, UsuarioId, AlbumId, Codigo (string, max 20), Nome (opcional), Quantidade, ImagemUrl (não usado)
- `Local`, `UsuarioLocal`, `Mensagem`: só V2

### Regras de negócio da coleção (vêm do site; a API e o app devem repeti-las igual)

- `Figurinha` é **por usuário**. Uma linha só existe depois que o usuário salva aquela figurinha. O `Album` guarda apenas o total (ex.: 512), não a lista.
- A grade de um álbum é de `1` até `QuantidadeTotalFigurinhas`. O código de cada figurinha é o número com **no mínimo 2 dígitos** (`i.ToString("D2")`): "01", "02", ..., "99", "100", ..., "512". Figurinha sem linha no banco = `Quantidade 0`.
- `Quantidade`: 0 = falta, 1 = colada, >1 = repetida. Número de repetidas de uma figurinha = `Quantidade - 1` (o selo da figurinha mostra `+N`).
- Progresso do álbum: `unicas = count(Quantidade > 0)`, `faltantes = total - unicas`, `progresso = round(unicas / total * 100)`.
- Home: `repetidas = soma(Quantidade - 1)` das figurinhas com `Quantidade > 1`. `faltantes = soma dos totais dos álbuns do usuário - figurinhas únicas nesses álbuns` (nunca negativo).
- Vincular álbum: se ainda não existe `UsuarioAlbum`, cria e faz `Album.UsuariosVinculados += 1`.
- Salvar figurinha: se existe linha (UsuarioId + AlbumId + Codigo) atualiza; senão cria. Nome vazio não apaga o nome existente.
- Listas de álbuns são ordenadas por `UsuariosVinculados` decrescente.
- URLs de imagem vêm **relativas** do banco (`/images/albuns/xxx.png`, `/images/default-avatar.png`). O app deve prefixar com a URL base e tratar imagem quebrada com um placeholder.

## Fase 1: criar a API no projeto web (C#)

Faça isto primeiro, de forma testável sem o app. Regras:

- Pasta nova `Controllers/Api/`, com `[ApiController]` e rotas `api/...`. **Não altere os Controllers MVC existentes** nem as Views.
- Autenticação por **JWT Bearer** (pacote `Microsoft.AspNetCore.Authentication.JwtBearer`). A chave secreta vem de configuração/variável de ambiente, nunca fixa no código nem commitada. No Render, configurar como variável de ambiente.
- Em `Program.cs`: registrar a autenticação JWT e chamar `app.UseAuthentication()` antes de `app.UseAuthorization()`. O MVC continua com sessão, sem mudanças.
- **Nunca copie o padrão `?? 1` do site.** Sem token válido, a API responde 401. O id do usuário vem sempre do token.
- Valide entradas: álbum existente, código dentro de 1..total, `quantidade` entre 0 e um limite razoável (ex.: 99).
- Devolva JSON em camelCase (padrão do ASP.NET). Não devolva entidades do EF direto; use DTOs (`record`) para não expor `SenhaHash`, CPF etc.

### Contrato

| Método e rota | Corpo | Resposta |
|---|---|---|
| `POST /api/auth/login` | `{ email, senha }` | `{ token, usuario: { id, nome, fotoUrl } }` ou 401 |
| `GET /api/home` | - | `{ nome, fotoUrl, repetidas, faltantes }` |
| `GET /api/albuns/meus` | - | `[ { id, nome, capaUrl, total, usuariosVinculados } ]` |
| `GET /api/albuns/catalogo` | - | `[ { id, nome, capaUrl, total, usuariosVinculados, jaColeciona } ]` |
| `POST /api/albuns/{id}/vincular` | - | 204 (idempotente: se já vinculado, também 204) |
| `GET /api/albuns/{id}/figurinhas` | - | `{ album:{id,nome,capaUrl}, total, unicas, faltantes, progresso, figurinhas:[ { codigo, nome, quantidade } ] }` com **todas** as figurinhas de 1..total (as sem linha vêm com `quantidade 0`), assim a regra do código "D2" fica só no servidor |
| `PUT /api/albuns/{id}/figurinhas/{codigo}` | `{ quantidade, nome }` | a figurinha atualizada |

**Senhas:** hoje são guardadas e comparadas em **texto puro** (apesar do nome `SenhaHash`). Para a V1 o login da API compara igual ao site, para os dois aceitarem as mesmas contas. É dívida técnica conhecida: anote em `PENDENCIAS.md` e não "conserte" só na API, senão o site quebra. Corrigir (hash com BCrypt ou `PasswordHasher`) nos dois ao mesmo tempo, depois do prazo.

## Fase 2: app Flutter

### Estrutura sugerida

```
lib/
  main.dart
  core/        config.dart (URL base), theme.dart, api_client.dart
  models/      usuario.dart, album.dart, figurinha.dart, resumo_figurinhas.dart
  services/    auth_service.dart, album_service.dart
  screens/     login, home, meus_albuns, catalogo, figurinhas, em_breve
  widgets/     card_album.dart, card_figurinha.dart, barra_progresso.dart, ...
```

### Decisões técnicas

- Pacotes: `http`, `flutter_secure_storage` (guardar o token), `google_fonts`, `provider` (estado). Peça confirmação antes de adicionar outros.
- Token no `flutter_secure_storage`; ao abrir o app, se há token, tenta entrar direto. Resposta 401 em qualquer chamada leva de volta ao login.
- Todas as telas tratam 3 estados: carregando, erro (com botão "tentar de novo") e vazio.
- Edição de figurinha: atualizar a tela na hora (otimista) e reverter com aviso se a API falhar.
- Os models em Dart espelham os DTOs da API (`fromJson`).

### Identidade visual

O visual do site (azul `#2563EB`, fonte Inter, cantos arredondados) foi escolhido por terceiros e **o usuário acha que parece aplicativo de hospital**. O app NÃO deve copiar o site.

- **Regra rígida:** nenhuma cor, fonte, raio de borda ou espaçamento fixo dentro das telas. Tudo vem de `lib/core/theme.dart` (`ThemeData` + constantes). Trocar a identidade tem que ser editar só esse arquivo.
- A identidade **ainda não foi definida**. Antes de desenhar a primeira tela, pergunte ao usuário: sentimento (nostalgia de banca de jornal, sticker pack de colecionador, cartas de jogo, arcade retrô?), 1 cor principal + 1 de destaque + fundo + texto, uma fonte de título com personalidade e outra legível, e a forma (cantos arredondados, retos, bordas grossas, sombras duras). Enquanto isso, use um tema neutro e provisório.
- Ideia que une identidade e função: figurinha **repetida** com brilho tipo "foil"; **faltante** como silhueta vazia; colada em cor cheia.

## Ordem de trabalho (um passo por vez; faça commit ao fim de cada um)

1. **API** (Fase 1), testada com chamadas HTTP de verdade (curl ou arquivo `.http`) contra o servidor local e depois contra o Render.
2. **Casca do app:** tema provisório, navegação com 4 abas, telas "Em breve".
3. **Login** real contra a API.
4. **Meus Álbuns** e **Catálogo** (+ vincular).
5. **Figurinhas do álbum** (grade, busca, filtro, edição). É a tela mais importante.
6. **Home** com contadores.
7. Identidade visual definitiva, polimento, ícone e nome do app.
8. Teste em celular real, correção de bugs, gerar o APK (`flutter build apk`).

Se o prazo apertar, corte nesta ordem: filtro de meus álbuns, busca no catálogo, polimento da Home. O que não pode faltar: login, ver álbuns, ver e editar figurinhas.

## Convenções

- Rode `flutter analyze` antes de concluir qualquer etapa e corrija os avisos.
- Não faça `git push`, nem apague arquivos, sem o usuário pedir.
- Segredos (chave JWT, connection string) nunca entram no repositório.
- Mudanças no projeto web ficam restritas à pasta `Controllers/Api/`, ao `Program.cs` (JWT) e a arquivos novos. Qualquer outra alteração no site precisa ser avisada e justificada.
- O site publicado no Render só reflete a API nova depois de um novo deploy. Avise o usuário quando for preciso publicar.
