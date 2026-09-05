using CompletaJaApp.Data;
using CompletaJaApp.Models;
using CompletaJaApp.Services;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using System;
using System.Threading.Tasks;

namespace CompletaJáApp.Controllers
{
    public class UsuarioController : Controller
    {
        private readonly CompletaJaContext _context;
        private readonly ImagemService _imagemService;
        private readonly IPasswordHasher<Usuario> _passwordHasher;

        public UsuarioController(
            CompletaJaContext context,
            ImagemService imagemService,
            IPasswordHasher<Usuario> passwordHasher)
        {
            _context = context;
            _imagemService = imagemService;
            _passwordHasher = passwordHasher;
        }

        // ==========================================
        // 1. EXIBE A TELA DE EDIÇÃO DO PERFIL
        // ==========================================
        [HttpGet]
        public IActionResult Editar()
        {
            int? meuId =
                HttpContext.Session.GetInt32("UsuarioId");

            if (meuId == null)
            {
                return RedirectToAction(
                    "Index",
                    "Account");
            }

            var usuario =
                _context.Usuarios.Find(meuId.Value);

            if (usuario == null)
            {
                return NotFound();
            }

            return View(usuario);
        }

        // ==========================================
        // 2. SALVA A NOVA SENHA E A NOVA FOTO
        // ==========================================
        [HttpPost]
        public async Task<IActionResult> Salvar(
            string? NovaSenha,
            IFormFile? NovaFoto)
        {
            int? meuId =
                HttpContext.Session.GetInt32("UsuarioId");

            if (meuId == null)
            {
                return RedirectToAction(
                    "Index",
                    "Account");
            }

            var usuario =
                _context.Usuarios.Find(meuId.Value);

            if (usuario == null)
            {
                return NotFound();
            }

            // Se uma nova senha foi preenchida,
            // ela será protegida antes de ser salva.
            if (!string.IsNullOrWhiteSpace(NovaSenha))
            {
                usuario.SenhaHash =
                    _passwordHasher.HashPassword(
                        usuario,
                        NovaSenha);
            }

            // Se uma nova foto foi selecionada,
            // ela será validada pelo ImagemService.
            if (NovaFoto != null &&
                NovaFoto.Length > 0)
            {
                try
                {
                    string novaFotoUrl =
                        await _imagemService.SalvarAsync(
                            NovaFoto,
                            "perfis");

                    usuario.FotoUrl = novaFotoUrl;

                    HttpContext.Session.SetString(
                        "FotoUsuario",
                        novaFotoUrl);
                }
                catch (InvalidOperationException ex)
                {
                    TempData["MensagemErro"] =
                        ex.Message;

                    return RedirectToAction("Editar");
                }
            }

            _context.SaveChanges();

            TempData["MensagemSucesso"] =
                "Perfil atualizado com sucesso!";

            return RedirectToAction("Editar");
        }
    }
}