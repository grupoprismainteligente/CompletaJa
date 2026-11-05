import 'package:flutter/foundation.dart';

/// Configuração do app: o único lugar que sabe o endereço do servidor.
///
/// Sem nenhuma opção, o app de DESENVOLVIMENTO (`flutter run`) usa o servidor local e o
/// APK de RELEASE (`flutter build apk`) usa o servidor de produção. Para forçar um deles:
///   flutter run --dart-define=AMBIENTE=producao
///   flutter build apk --dart-define=AMBIENTE=desenvolvimento
///   flutter run --dart-define=API_URL=http://192.168.0.10:5022   (celular real na mesma rede)
class AppConfig {
  AppConfig._();

  /// `String.fromEnvironment` lê o valor do `--dart-define` na hora de compilar.
  /// Vazio = o padrão do modo de compilação (ver `producao`).
  static const String _ambiente = String.fromEnvironment('AMBIENTE');
  static const String _urlManual = String.fromEnvironment('API_URL');

  /// No emulador Android, `10.0.2.2` é o "localhost" do computador onde ele roda.
  /// Esse endereço só existe lá dentro: no Chrome (`kIsWeb`) o servidor é `localhost` mesmo.
  static String get urlDesenvolvimento => kIsWeb ? 'http://localhost:5022' : 'http://10.0.2.2:5022';

  /// Site no Render (HTTPS). O plano gratuito dorme: a 1ª chamada pode levar 30-60 s.
  static const String urlProducao = 'https://completaja-prisma.onrender.com';

  /// `kReleaseMode` é verdadeiro só no APK de release: assim ninguém publica um app
  /// apontando para o `10.0.2.2` (que só existe dentro do emulador).
  static bool get producao => _ambiente.isEmpty ? kReleaseMode : _ambiente == 'producao';

  /// URL base sem barra no final.
  static String get urlBase {
    if (_urlManual.isNotEmpty) return _urlManual;
    return producao ? urlProducao : urlDesenvolvimento;
  }

  /// Timeout longo de propósito: o Render pode demorar para acordar (>= 90 s no CLAUDE.md).
  static const Duration timeout = Duration(seconds: 90);

  /// Depois deste tempo sem resposta, a tela avisa que o servidor está acordando.
  static const Duration avisoServidorAcordando = Duration(seconds: 5);

  /// O banco guarda imagens de dois jeitos: URL completa (Cloudinary) ou relativa
  /// (`/images/default-avatar.png`). Só a relativa precisa do endereço do servidor na frente.
  static String? urlImagem(String? caminho) {
    if (caminho == null || caminho.isEmpty) return null;
    if (caminho.startsWith('http://') || caminho.startsWith('https://')) return caminho;
    return '$urlBase${caminho.startsWith('/') ? '' : '/'}$caminho';
  }
}
