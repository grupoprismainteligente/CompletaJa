using CompletaJaApp.Data;
using CompletaJaApp.Models;
using CompletaJaApp.Services;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using System;
using System.Security.Cryptography;
using System.Text;
using System.Linq;
using System.Threading.Tasks;

namespace CompletaJáApp.Controllers
{
    public class AccountController : Controller
    {
        private readonly CompletaJaContext _context;
        private readonly ImagemService _imagemService;
        private readonly IPasswordHasher<Usuario> _passwordHasher;
        private readonly LoginAttemptService _tentativas;
        private readonly IEmailService _email;
        private readonly ILogger<AccountController> _logger;

        public AccountController(
            CompletaJaContext context,
            ImagemService imagemService,
            IPasswordHasher<Usuario> passwordHasher,
            LoginAttemptService tentativas,
            IEmailService email,
            ILogger<AccountController> logger)
        {
            _context = context;
            _imagemService = imagemService;
            _passwordHasher = passwordHasher;
            _tentativas = tentativas;
            _email = email;
            _logger = logger;
        }

        // SHA-256 em hexadecimal (64 caracteres) do token de recuperação
        private static string HashToken(string token) =>
            Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(token)));

        // Exibe a tela de login e cadastro
        [HttpGet]
        public IActionResult Index()
        {
            return View();
        }

        // Processa o login
        [HttpPost]
        [EnableRateLimiting("login")]
        public IActionResult Login(string Email, string Senha)
        {
            if (string.IsNullOrEmpty(Email) ||
                string.IsNullOrEmpty(Senha))
            {
                ViewBag.Erro = "Preencha todos os campos.";
                return View("Index");
            }

            // Bloqueio temporário após 5 senhas erradas para o mesmo e-mail
            if (_tentativas.EstaBloqueado(Email, out var minutos))
            {
                ViewBag.Erro =
                    $"Muitas tentativas de login. Tente novamente em {minutos} minuto(s).";
                return View("Index");
            }

            var usuario = _context.Usuarios
                .FirstOrDefault(u => u.Email == Email);

            if (usuario != null)
            {
                PasswordVerificationResult resultadoSenha;

                try
                {
                    resultadoSenha =
                        _passwordHasher.VerifyHashedPassword(
                            usuario,
                            usuario.SenhaHash ?? string.Empty,
                            Senha);
                }
                catch (FormatException)
                {
                    resultadoSenha =
                        PasswordVerificationResult.Failed;
                }

                if (resultadoSenha !=
                    PasswordVerificationResult.Failed)
                {
                    if (resultadoSenha ==
                        PasswordVerificationResult.SuccessRehashNeeded)
                    {
                        usuario.SenhaHash =
                            _passwordHasher.HashPassword(
                                usuario,
                                Senha);

                        _context.SaveChanges();
                    }

                    _tentativas.Limpar(Email);

                    // Novo ciclo de sessão após autenticar
                    HttpContext.Session.Clear();

                    HttpContext.Session.SetInt32(
                        "UsuarioId",
                        usuario.Id);

                    HttpContext.Session.SetString(
                        "NomeUsuario",
                        usuario.Nome ?? string.Empty);

                    HttpContext.Session.SetString(
                        "FotoUsuario",
                        usuario.FotoUrl ?? string.Empty);

                    return RedirectToAction(
                        "Index",
                        "Home");
                }
            }

            _tentativas.RegistrarFalha(Email);

            ViewBag.Erro = "Usuário ou senha inválidos!";
            return View("Index");
        }

        // Processa o cadastro de um novo usuário
        [HttpPost]
        public async Task<IActionResult> Register(
            string Nome,
            string Email,
            string CPF,
            string Senha,
            string ConfirmaSenha,
            IFormFile? FotoPerfil)
        {
            // Validação no servidor (a do JavaScript pode ser contornada)
            if (!CpfHelper.Validar(CPF))
            {
                ViewBag.Erro = "O CPF informado é inválido.";
                return View("Index");
            }

            if (Senha != ConfirmaSenha)
            {
                ViewBag.Erro =
                    "As senhas não coincidem.";

                return View("Index");
            }

            if (_context.Usuarios.Any(
                u => u.Email == Email))
            {
                ViewBag.Erro =
                    "Este e-mail já está em uso.";

                return View("Index");
            }

            string fotoUrl =
                "/images/default-avatar.png";

            if (FotoPerfil != null &&
                FotoPerfil.Length > 0)
            {
                try
                {
                    fotoUrl =
                        await _imagemService.SalvarAsync(
                            FotoPerfil,
                            "usuarios");
                }
                catch (InvalidOperationException ex)
                {
                    ViewBag.Erro = ex.Message;
                    return View("Index");
                }
            }

            var novoUsuario = new Usuario
            {
                Nome = Nome,
                Email = Email,
                // LGPD (minimização): só guardamos o CPF mascarado
                CPF = CpfHelper.Mascarar(CPF),
                SenhaHash = string.Empty,
                FotoUrl = fotoUrl
            };

            novoUsuario.SenhaHash =
                _passwordHasher.HashPassword(
                    novoUsuario,
                    Senha);

            _context.Usuarios.Add(novoUsuario);
            _context.SaveChanges();

            TempData["Sucesso"] =
                "Conta criada com sucesso! Faça seu login.";

            return RedirectToAction(
                "Index",
                "Account");
        }

        // Exibe os termos de uso
        [HttpGet]
        public IActionResult Termos()
        {
            return View();
        }

        // Exibe a página de recuperação de senha
        [HttpGet]
        public IActionResult ForgotPassword()
        {
            return View();
        }

        // Processa a solicitação de recuperação de senha
        [HttpPost]
        [EnableRateLimiting("recuperacao")]
        public async Task<IActionResult> ForgotPassword(string Email)
        {
            if (string.IsNullOrWhiteSpace(Email))
            {
                ViewBag.Erro =
                    "Por favor, informe seu e-mail.";

                return View();
            }

            var usuario = _context.Usuarios
                .FirstOrDefault(u => u.Email == Email);

            if (usuario != null)
            {
                // Token aleatório de 256 bits; só o hash vai para o banco
                var token = Convert.ToHexString(RandomNumberGenerator.GetBytes(32));

                // Invalida pedidos anteriores ainda abertos
                var antigos = _context.RedefinicoesSenha
                    .Where(r => r.UsuarioId == usuario.Id && !r.Usado)
                    .ToList();

                foreach (var a in antigos)
                    a.Usado = true;

                _context.RedefinicoesSenha.Add(new RedefinicaoSenha
                {
                    UsuarioId = usuario.Id,
                    TokenHash = HashToken(token),
                    ExpiraEm = DateTime.UtcNow.AddMinutes(30),
                    Usado = false
                });

                _context.SaveChanges();

                var link = Url.Action(
                    "ResetPassword",
                    "Account",
                    new { token },
                    Request.Scheme);

                try
                {
                    await _email.EnviarAsync(
                        usuario.Email!,
                        "CompletaJá - Redefinição de senha",
                        $"<p>Olá, {System.Net.WebUtility.HtmlEncode(usuario.Nome)}!</p>" +
                        $"<p>Para criar uma nova senha, acesse o link abaixo (válido por 30 minutos):</p>" +
                        $"<p><a href=\"{link}\">{link}</a></p>" +
                        "<p>Se você não pediu isso, ignore este e-mail.</p>");
                }
                catch (Exception ex)
                {
                    // Não revelamos a falha ao usuário (evita enumeração de contas)
                    _logger.LogError(ex, "Falha ao enviar e-mail de recuperação.");
                }
            }

            // Mesma resposta exista ou não a conta: não revela quem está cadastrado
            ViewBag.Sucesso =
                "Se este e-mail estiver cadastrado, enviamos um link para redefinir a senha. O link vale por 30 minutos.";

            return View();
        }

        // Tela para digitar a nova senha (link recebido por e-mail)
        [HttpGet]
        public IActionResult ResetPassword(string token)
        {
            if (!TokenValido(token, out _))
            {
                ViewBag.TokenInvalido = true;
                return View();
            }

            ViewBag.Token = token;
            return View();
        }

        [HttpPost]
        [EnableRateLimiting("recuperacao")]
        public IActionResult ResetPassword(string token, string Senha, string ConfirmaSenha)
        {
            if (!TokenValido(token, out var pedido) || pedido == null)
            {
                ViewBag.TokenInvalido = true;
                return View();
            }

            ViewBag.Token = token;

            if (string.IsNullOrEmpty(Senha) || Senha.Length < 8)
            {
                ViewBag.Erro = "A senha deve ter pelo menos 8 caracteres.";
                return View();
            }

            if (Senha != ConfirmaSenha)
            {
                ViewBag.Erro = "As senhas não coincidem.";
                return View();
            }

            var usuario = _context.Usuarios.Find(pedido.UsuarioId);

            if (usuario == null)
            {
                ViewBag.TokenInvalido = true;
                return View();
            }

            usuario.SenhaHash = _passwordHasher.HashPassword(usuario, Senha);
            pedido.Usado = true; // uso único

            _context.SaveChanges();
            _tentativas.Limpar(usuario.Email);

            TempData["Sucesso"] =
                "Senha redefinida com sucesso! Faça seu login.";

            return RedirectToAction("Index", "Account");
        }

        private bool TokenValido(string? token, out RedefinicaoSenha? pedido)
        {
            pedido = null;

            if (string.IsNullOrWhiteSpace(token))
                return false;

            var hash = HashToken(token);

            pedido = _context.RedefinicoesSenha
                .FirstOrDefault(r => r.TokenHash == hash);

            return pedido != null
                && !pedido.Usado
                && pedido.ExpiraEm > DateTime.UtcNow;
        }
    }
}