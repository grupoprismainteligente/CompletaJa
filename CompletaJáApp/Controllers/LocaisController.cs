using CompletaJaApp.Data;
using CompletaJaApp.Models;
using CompletaJaApp.Services;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System;
using System.Linq;
using System.Threading.Tasks;

namespace CompletaJáApp.Controllers
{
    public class LocaisController : Controller
    {
        private readonly CompletaJaContext _context;
        private readonly ImagemService _imagemService;

        public LocaisController(
            CompletaJaContext context,
            ImagemService imagemService)
        {
            _context = context;
            _imagemService = imagemService;
        }

        // ==========================================
        // 1. MOSTRA OS LOCAIS DO USUÁRIO
        // ==========================================
        public async Task<IActionResult> Index()
        {
            ViewBag.FotoUsuario =
                HttpContext.Session.GetString("FotoUsuario")
                ?? "/images/default-avatar.png";

            int usuarioId =
                HttpContext.Session
                    .GetInt32("UsuarioId")!
                    .Value;

            var locaisVinculadosIds =
                await _context.UsuariosLocais
                    .Where(ul =>
                        ul.UsuarioId == usuarioId)
                    .Select(ul => ul.LocalId)
                    .ToListAsync();

            var meusLocais =
                await _context.Locais
                    .Where(l =>
                        locaisVinculadosIds.Contains(l.Id))
                    .OrderByDescending(
                        l => l.UsuariosVinculados)
                    .ToListAsync();

            return View(meusLocais);
        }

        // ==========================================
        // 2. MOSTRA TODOS OS LOCAIS DISPONÍVEIS
        // ==========================================
        public async Task<IActionResult> Buscar()
        {
            ViewBag.FotoUsuario =
                HttpContext.Session.GetString("FotoUsuario")
                ?? "/images/default-avatar.png";

            int usuarioId =
                HttpContext.Session
                    .GetInt32("UsuarioId")!
                    .Value;

            ViewBag.MeusLocaisIds =
                await _context.UsuariosLocais
                    .Where(ul =>
                        ul.UsuarioId == usuarioId)
                    .Select(ul => ul.LocalId)
                    .ToListAsync();

            var todosLocais =
                await _context.Locais
                    .OrderByDescending(
                        l => l.UsuariosVinculados)
                    .ToListAsync();

            return View(todosLocais);
        }

        // ==========================================
        // 3. VINCULA O USUÁRIO A UM LOCAL
        // ==========================================
        [HttpPost]
        public async Task<IActionResult> Vincular(
            int localId)
        {
            int usuarioId =
                HttpContext.Session
                    .GetInt32("UsuarioId")!
                    .Value;

            bool jaEstaVinculado =
                await _context.UsuariosLocais.AnyAsync(
                    ul =>
                        ul.UsuarioId == usuarioId &&
                        ul.LocalId == localId);

            if (!jaEstaVinculado)
            {
                _context.UsuariosLocais.Add(
                    new UsuarioLocal
                    {
                        UsuarioId = usuarioId,
                        LocalId = localId
                    });

                var local =
                    await _context.Locais.FindAsync(localId);

                if (local != null)
                {
                    local.UsuariosVinculados += 1;
                }

                await _context.SaveChangesAsync();
            }

            return RedirectToAction(nameof(Index));
        }

        // ==========================================
        // 4. MOSTRA OS DETALHES DE UM LOCAL
        // ==========================================
        public async Task<IActionResult> Detalhes(
            int id)
        {
            ViewBag.FotoUsuario =
                HttpContext.Session.GetString("FotoUsuario")
                ?? "/images/default-avatar.png";

            var local =
                await _context.Locais.FindAsync(id);

            if (local == null)
            {
                return NotFound();
            }

            return View(local);
        }

        // ==========================================
        // 5. REMOVE O VÍNCULO DO USUÁRIO COM O LOCAL
        // ==========================================
        [HttpPost]
        public async Task<IActionResult> Desvincular(
            int localId)
        {
            int usuarioId =
                HttpContext.Session
                    .GetInt32("UsuarioId")!
                    .Value;

            var vinculo =
                await _context.UsuariosLocais
                    .FirstOrDefaultAsync(
                        ul =>
                            ul.UsuarioId == usuarioId &&
                            ul.LocalId == localId);

            if (vinculo != null)
            {
                _context.UsuariosLocais.Remove(vinculo);

                var local =
                    await _context.Locais.FindAsync(localId);

                if (local != null &&
                    local.UsuariosVinculados > 0)
                {
                    local.UsuariosVinculados -= 1;
                }

                await _context.SaveChangesAsync();
            }

            return RedirectToAction(nameof(Index));
        }

        // ==========================================
        // 6. EXIBE O FORMULÁRIO DE NOVO LOCAL
        // ==========================================
        public IActionResult Add()
        {
            ViewBag.FotoUsuario =
                HttpContext.Session.GetString("FotoUsuario")
                ?? "/images/default-avatar.png";

            return View();
        }

        // ==========================================
        // 7. CADASTRA UM NOVO LOCAL
        // ==========================================
        [HttpPost]
        public async Task<IActionResult> Criar(
            Local novoLocal,
            IFormFile? Foto)
        {
            if (!ModelState.IsValid)
            {
                TempData["ErroUpload"] =
                    "Preencha corretamente os dados do local.";

                return RedirectToAction(nameof(Add));
            }

            if (Foto != null &&
                Foto.Length > 0)
            {
                try
                {
                    novoLocal.FotoUrl =
                        await _imagemService.SalvarAsync(
                            Foto,
                            "locais");
                }
                catch (InvalidOperationException ex)
                {
                    TempData["ErroUpload"] =
                        ex.Message;

                    return RedirectToAction(nameof(Add));
                }
            }
            else
            {
                novoLocal.FotoUrl =
                    "/images/default-local.jpg";
            }

            novoLocal.UsuariosVinculados = 1;

            _context.Locais.Add(novoLocal);
            await _context.SaveChangesAsync();

            int usuarioId =
                HttpContext.Session
                    .GetInt32("UsuarioId")!
                    .Value;

            _context.UsuariosLocais.Add(
                new UsuarioLocal
                {
                    UsuarioId = usuarioId,
                    LocalId = novoLocal.Id
                });

            await _context.SaveChangesAsync();

            return RedirectToAction(nameof(Index));
        }

        // ==========================================
        // 8. VERIFICA SE O CNPJ JÁ ESTÁ CADASTRADO
        // ==========================================
        [HttpPost]
        public async Task<IActionResult> VerificarDuplicidade(
            string cnpj)
        {
            if (string.IsNullOrEmpty(cnpj))
            {
                return BadRequest();
            }

            var localExistente =
                await _context.Locais
                    .FirstOrDefaultAsync(
                        l => l.CNPJ == cnpj);

            if (localExistente != null)
            {
                return Json(
                    new
                    {
                        duplicado = true,
                        nomeLocal = localExistente.Nome
                    });
            }

            return Json(
                new
                {
                    duplicado = false
                });
        }
    }
}