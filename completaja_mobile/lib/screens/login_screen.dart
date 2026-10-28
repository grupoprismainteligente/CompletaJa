import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../core/config.dart';
import '../core/theme.dart';
import '../services/auth_service.dart';
import '../widgets/aviso.dart';

/// Login real: chama `POST /api/auth/login` pelo `AuthService`. Se der certo, o
/// `PortaDeEntrada` (main.dart) troca esta tela pela Home sozinho.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controllers leem o que foi digitado em cada campo.
  final _email = TextEditingController();
  final _senha = TextEditingController();

  bool _modoEntrar = true; // false = aba "Criar Conta"
  bool _senhaVisivel = false;
  String? _erro;

  bool _carregando = false;

  // O servidor gratuito dorme: se a resposta demora, avisamos em vez de parecer travado.
  bool _servidorAcordando = false;
  Timer? _avisoAcordando;

  // Controllers precisam ser liberados quando a tela sai, senão vazam memória.
  @override
  void dispose() {
    _avisoAcordando?.cancel();
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (_carregando) return; // evita toque duplo enquanto a chamada está em andamento
    if (_email.text.trim().isEmpty || _senha.text.isEmpty) {
      setState(() => _erro = 'Informe e-mail e senha.');
      return;
    }

    // Lido antes do await: usar `context` depois de uma espera exige conferir `mounted`.
    final auth = context.read<AuthService>();
    setState(() {
      _erro = null;
      _carregando = true;
      _servidorAcordando = false;
    });
    _avisoAcordando = Timer(AppConfig.avisoServidorAcordando, () {
      if (mounted) setState(() => _servidorAcordando = true);
    });

    try {
      await auth.entrar(_email.text, _senha.text);
      // Sucesso: o AuthService avisou e o PortaDeEntrada já trocou para a Home.
    } on ApiException catch (e) {
      if (mounted) setState(() => _erro = e.mensagem);
    } catch (_) {
      if (mounted) setState(() => _erro = 'Algo deu errado ao entrar. Tente de novo.');
    } finally {
      _avisoAcordando?.cancel();
      if (mounted) {
        setState(() {
          _carregando = false;
          _servidorAcordando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCores.fundoPagina,
      body: SafeArea(
        child: Center(
          // SingleChildScrollView evita estouro quando o teclado abre.
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppEspacos.lateral,
              vertical: AppEspacos.enorme,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 390),
              child: Column(
                children: [
                  _cabecalho(),
                  const SizedBox(height: AppEspacos.lateral),
                  _painel(),
                  const SizedBox(height: AppEspacos.grande),
                  _rodape(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _cabecalho() {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppCores.primaria,
            borderRadius: BorderRadius.circular(AppRaios.medio),
          ),
          child: const Icon(Icons.layers, color: AppCores.superficie, size: 26),
        ),
        const SizedBox(height: AppEspacos.compacto),
        Text('CompletaJá', style: AppTextos.loginTitulo),
        const SizedBox(height: AppEspacos.minimo),
        Text('Complete seu álbum com amigos!', style: AppTextos.loginSubtitulo),
      ],
    );
  }

  Widget _painel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppEspacos.lateral),
      decoration: BoxDecoration(
        color: AppCores.superficie,
        borderRadius: BorderRadius.circular(AppRaios.painel),
        boxShadow: AppSombras.painel,
      ),
      child: Column(
        children: [
          _alternador(),
          const SizedBox(height: AppEspacos.grande),
          if (_modoEntrar) _formLogin() else _avisoCadastro(),
        ],
      ),
    );
  }

  // Os dois botões "Entrar" / "Criar Conta" no topo do painel.
  Widget _alternador() {
    return Container(
      padding: const EdgeInsets.all(AppEspacos.minimo),
      decoration: BoxDecoration(
        color: AppCores.alternador,
        borderRadius: BorderRadius.circular(AppRaios.medio),
      ),
      child: Row(
        children: [
          _abaAlternador('Entrar', true),
          _abaAlternador('Criar Conta', false),
        ],
      ),
    );
  }

  Widget _abaAlternador(String texto, bool entrar) {
    final ativo = _modoEntrar == entrar;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _modoEntrar = entrar),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppEspacos.compacto - 2),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: ativo ? AppCores.superficie : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRaios.campo),
          ),
          child: Text(texto, style: ativo ? AppTextos.alternadorAtivo : AppTextos.alternadorTexto),
        ),
      ),
    );
  }

  Widget _formLogin() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_erro != null) _caixaErro(_erro!),
        _campo(
          rotulo: 'E-mail',
          icone: Icons.mail_outline,
          controller: _email,
          dica: 'seu@email.com',
          teclado: TextInputType.emailAddress,
        ),
        _campo(
          rotulo: 'Senha',
          icone: Icons.lock,
          controller: _senha,
          dica: '••••••••',
          senha: true,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () => mostrarAviso(context, 'A recuperação de senha fica disponível no site.'),
            child: Text('Esqueceu a senha?', style: AppTextos.linkPequeno),
          ),
        ),
        const SizedBox(height: AppEspacos.lateral),
        SizedBox(
          width: double.infinity,
          height: AppTamanhos.alturaBotao,
          child: ElevatedButton(
            // null desabilita o botão enquanto a chamada está em andamento.
            onPressed: _carregando ? null : _entrar,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppCores.primariaEscura,
              foregroundColor: AppCores.superficie,
              disabledBackgroundColor: AppCores.primariaEscura,
              disabledForegroundColor: AppCores.superficie,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRaios.medio)),
            ),
            child: _carregando
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: AppCores.superficie),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Entrar', style: AppTextos.botaoLogin),
                      const SizedBox(width: AppEspacos.pequeno),
                      const Icon(Icons.arrow_forward, size: 18),
                    ],
                  ),
          ),
        ),
        if (_servidorAcordando)
          Padding(
            padding: const EdgeInsets.only(top: AppEspacos.compacto),
            child: Center(
              child: Text(
                'Acordando o servidor, isso pode levar até 1 minuto na primeira vez...',
                textAlign: TextAlign.center,
                style: AppTextos.rodapeLogin,
              ),
            ),
          ),
      ],
    );
  }

  // A criação de conta continua sendo feita no site (decisão do projeto).
  Widget _avisoCadastro() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppEspacos.grande),
      child: Column(
        children: [
          const Icon(Icons.language, size: 40, color: AppCores.primaria),
          const SizedBox(height: AppEspacos.compacto),
          Text(
            'O cadastro de novas contas é feito pelo site do CompletaJá. Depois é só entrar aqui com o mesmo e-mail e senha.',
            textAlign: TextAlign.center,
            style: AppTextos.emBreveTexto,
          ),
        ],
      ),
    );
  }

  Widget _caixaErro(String mensagem) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppEspacos.medio),
      padding: const EdgeInsets.all(AppEspacos.campo),
      decoration: BoxDecoration(
        color: AppCores.erroFundo,
        borderRadius: BorderRadius.circular(AppRaios.campo),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 16, color: AppCores.erro),
          const SizedBox(width: AppEspacos.minimo),
          Text(mensagem, style: AppTextos.alertaErro),
        ],
      ),
    );
  }

  Widget _campo({
    required String rotulo,
    required IconData icone,
    required TextEditingController controller,
    required String dica,
    TextInputType? teclado,
    bool senha = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppEspacos.medio),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: AppEspacos.minimo, bottom: AppEspacos.minimo),
            child: Text(rotulo, style: AppTextos.rotuloCampo),
          ),
          Container(
            height: AppTamanhos.alturaCampo,
            padding: const EdgeInsets.symmetric(horizontal: AppEspacos.medio),
            decoration: BoxDecoration(
              color: AppCores.campo,
              borderRadius: BorderRadius.circular(AppRaios.medio),
            ),
            child: Row(
              children: [
                Icon(icone, size: 18, color: AppCores.textoDesabilitado),
                const SizedBox(width: AppEspacos.campo),
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType: teclado,
                    obscureText: senha && !_senhaVisivel,
                    style: AppTextos.campoEntrada,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: dica,
                      hintStyle: AppTextos.dicaCampo,
                      isCollapsed: true,
                    ),
                  ),
                ),
                if (senha)
                  GestureDetector(
                    onTap: () => setState(() => _senhaVisivel = !_senhaVisivel),
                    child: Icon(
                      _senhaVisivel ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 18,
                      color: AppCores.textoDesabilitado,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rodape() {
    return Column(
      children: [
        Text('Ao continuar, você concorda com nossos', style: AppTextos.rodapeLogin),
        GestureDetector(
          onTap: () => mostrarAviso(context, 'Os Termos de Uso estão disponíveis no site.'),
          child: Text(
            'Termos de Uso e Privacidade',
            style: AppTextos.rodapeLogin.copyWith(
              color: AppCores.primaria,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
