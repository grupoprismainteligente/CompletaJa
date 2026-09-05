using CompletaJaApp.Data;
using CompletaJaApp.Models;
using CompletaJaApp.Services;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using System;
using System.Linq;
using System.Threading.Tasks;

namespace CompletaJáApp.Controllers
{
    public class AccountController : Controller
    {
        private readonly CompletaJaContext _context;
        private readonly ImagemService _imagemService;
        private readonly IPasswordHasher<Usuario> _passwordHasher;

        public AccountController(
            CompletaJaContext context,
            ImagemService imagemService,
            IPasswordHasher<Usuario> passwordHasher)
        {
            _context = context;
            _imagemService = imagemService;
            _passwordHasher = passwordHasher;
        }

        // Exibe a tela de login e cadastro
        [HttpGet]
        public IActionResult Index()
        {
            return View();
        }

        // Processa o login
        [HttpPost]
        public IActionResult Login(string Email, string Senha)
        {
            if (string.IsNullOrEmpty(Email) ||
                string.IsNullOrEmpty(Senha))
            {
                ViewBag.Erro = "Preencha todos os campos.";
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
                CPF = CPF,
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
        public IActionResult ForgotPassword(string Email)
        {
            if (string.IsNullOrEmpty(Email))
            {
                ViewBag.Erro =
                    "Por favor, informe seu e-mail.";

                return View();
            }

            var usuarioExiste =
                _context.Usuarios.Any(
                    u => u.Email == Email);

            if (!usuarioExiste)
            {
                ViewBag.Erro =
                    "Este e-mail não foi encontrado em nossa base de dados.";

                return View();
            }

            ViewBag.Sucesso =
                $"Tudo certo! As instruções de recuperação foram enviadas para o e-mail {Email} (Simulação).";

            return View();
        }
    }
}