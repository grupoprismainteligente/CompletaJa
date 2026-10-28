/// Configuração do app: o único lugar que sabe o endereço do servidor.
///
/// Para trocar de servidor sem editar código, passe `--dart-define` ao rodar:
///   flutter run --dart-define=AMBIENTE=producao
///   flutter run --dart-define=API_URL=http://192.168.0.10:5022   (celular real na mesma rede)
class AppConfig {
  AppConfig._();

  /// `String.fromEnvironment` lê o valor do `--dart-define` na hora de compilar.
  static const String _ambiente = String.fromEnvironment('AMBIENTE', defaultValue: 'desenvolvimento');
  static const String _urlManual = String.fromEnvironment('API_URL');

  /// No emulador Android, `10.0.2.2` é o "localhost" do computador onde ele roda.
  static const String urlDesenvolvimento = 'http://10.0.2.2:5022';

  /// Site no Render (HTTPS). O plano gratuito dorme: a 1ª chamada pode levar 30-60 s.
  static const String urlProducao = 'https://completaja-prisma.onrender.com';

  static bool get producao => _ambiente == 'producao';

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
