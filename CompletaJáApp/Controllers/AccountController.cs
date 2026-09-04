using Microsoft.AspNetCore.Mvc;
using CompletaJaApp.Data;
using CompletaJaApp.Models;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using System.IO;
using System;
using System.Threading.Tasks;
using System.Linq;
using Microsoft.AspNetCore.Identity;

namespace CompletaJáApp.Controllers
{
    public class AccountController : Controller
    {
        private readonly CompletaJaContext _context;
        private readonly IWebHostEnvironment _env;
        private readonly IPasswordHasher<Usuario> _passwordHasher;

        public AccountController(
            CompletaJaContext context,
            IWebHostEnvironment env,
            IPasswordHasher<Usuario> passwordHasher)
        {
            _context = context;
            _env = env;
            _passwordHasher = passwordHasher;
        }

        [HttpGet]
        public IActionResult Index() => View();

        [HttpPost]
        public IActionResult Login(string Email, string Senha)
        {
            if (string.IsNullOrEmpty(Email) || string.IsNullOrEmpty(Senha))
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
                    resultadoSenha = _passwordHasher.VerifyHashedPassword(
                        usuario,
                        usuario.SenhaHash ?? string.Empty,
                        Senha);
                }
                catch (FormatException)
                {
                    resultadoSenha = PasswordVerificationResult.Failed;
                }

                if (resultadoSenha != PasswordVerificationResult.Failed)
                {
                    if (resultadoSenha == PasswordVerificationResult.SuccessRehashNeeded)
                    {
                        usuario.SenhaHash = _passwordHasher.HashPassword(usuario, Senha);
                        _context.SaveChanges();
                    }

                    HttpContext.Session.SetInt32("UsuarioId", usuario.Id);
                    HttpContext.Session.SetString(
                        "NomeUsuario",
                        usuario.Nome ?? string.Empty);

                    HttpContext.Session.SetString(
                        "FotoUsuario",
                        usuario.FotoUrl ?? string.Empty);

                    return RedirectToAction("Index", "Home");
                }
            }

            ViewBag.Erro = "Usuário ou senha inválidos!";
            return View("Index");
        }

        [HttpPost]
        public async Task<IActionResult> Register(string Nome, string Email, string CPF, string Senha, string ConfirmaSenha, IFormFile FotoPerfil)
        {
            if (Senha != ConfirmaSenha)
            {
                ViewBag.Erro = "As senhas não coincidem.";
                return View("Index");
            }

            if (_context.Usuarios.Any(u => u.Email == Email))
            {
                ViewBag.Erro = "Este e-mail já está em uso.";
                return View("Index");
            }

            string fotoUrl = "/images/default-avatar.png";

            if (FotoPerfil != null && FotoPerfil.Length > 0)
            {
                string extensao = Path.GetExtension(FotoPerfil.FileName);
                string nomeArquivo = Guid.NewGuid().ToString() + extensao;
                string caminhoPasta = Path.Combine(_env.WebRootPath, "uploads", "usuarios");

                if (!Directory.Exists(caminhoPasta)) Directory.CreateDirectory(caminhoPasta);

                string caminhoCompleto = Path.Combine(caminhoPasta, nomeArquivo);
                using (var stream = new FileStream(caminhoCompleto, FileMode.Create))
                {
                    await FotoPerfil.CopyToAsync(stream);
                }

                fotoUrl = "/uploads/usuarios/" + nomeArquivo;
            }

            var novoUsuario = new Usuario
            {
                Nome = Nome,
                Email = Email,
                CPF = CPF,
                SenhaHash = string.Empty,
                FotoUrl = fotoUrl
            };

            novoUsuario.SenhaHash = _passwordHasher.HashPassword(novoUsuario, Senha);

            _context.Usuarios.Add(novoUsuario);
            _context.SaveChanges();

            TempData["Sucesso"] = "Conta criada com sucesso! Faça seu login.";
            return RedirectToAction("Index", "Account");
        }

        [HttpGet]
        public IActionResult Termos() => View();

        [HttpGet]
        public IActionResult ForgotPassword() => View();

        [HttpPost]
        public IActionResult ForgotPassword(string Email)
        {
            // 1. Verifica se o usuário digitou algo
            if (string.IsNullOrEmpty(Email))
            {
                ViewBag.Erro = "Por favor, informe seu e-mail.";
                return View();
            }

            // 2. SIMULAÇÃO: Verifica no Banco de Dados se o e-mail realmente existe
            var usuarioExiste = _context.Usuarios.Any(u => u.Email == Email);

            if (!usuarioExiste)
            {
                // Se não existe, devolvemos a mensagem de erro para a tela
                ViewBag.Erro = "Este e-mail não foi encontrado em nossa base de dados.";
                return View();
            }

            // 3. Se chegou aqui, o e-mail existe! Ativamos a mensagem de sucesso
            ViewBag.Sucesso = $"Tudo certo! As instruções de recuperação foram enviadas para o e-mail {Email} (Simulação).";
            return View();
        }
    }
}