using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Http;
using CompletaJaApp.Data;
using CompletaJaApp.Models;
using System.IO;
using System.Threading.Tasks;
using System.Linq;
using System;

namespace CompletaJáApp.Controllers
{
    public class LocaisController : Controller
    {
        private readonly CompletaJaContext _context;

        public LocaisController(CompletaJaContext context)
        {
            _context = context;
        }

        public async Task<IActionResult> Index()
        {
            ViewBag.FotoUsuario = HttpContext.Session.GetString("FotoUsuario") ?? "/images/default-avatar.png";
            int usuarioId = HttpContext.Session.GetInt32("UsuarioId")!.Value;

            var locaisVinculadosIds = await _context.UsuariosLocais
                .Where(ul => ul.UsuarioId == usuarioId)
                .Select(ul => ul.LocalId)
                .ToListAsync();

            var meusLocais = await _context.Locais
                .Where(l => locaisVinculadosIds.Contains(l.Id))
                .OrderByDescending(l => l.UsuariosVinculados)
                .ToListAsync();

            return View(meusLocais);
        }

        public async Task<IActionResult> Buscar()
        {
            ViewBag.FotoUsuario = HttpContext.Session.GetString("FotoUsuario") ?? "/images/default-avatar.png";
            int usuarioId = HttpContext.Session.GetInt32("UsuarioId")!.Value;

            ViewBag.MeusLocaisIds = await _context.UsuariosLocais
                .Where(ul => ul.UsuarioId == usuarioId)
                .Select(ul => ul.LocalId)
                .ToListAsync();

            var todosLocais = await _context.Locais
                .OrderByDescending(l => l.UsuariosVinculados)
                .ToListAsync();

            return View(todosLocais);
        }

        [HttpPost]
        public async Task<IActionResult> Vincular(int localId)
        {
            int usuarioId = HttpContext.Session.GetInt32("UsuarioId")!.Value;

            if (!await _context.UsuariosLocais.AnyAsync(ul => ul.UsuarioId == usuarioId && ul.LocalId == localId))
            {
                _context.UsuariosLocais.Add(new UsuarioLocal { UsuarioId = usuarioId, LocalId = localId });

                var local = await _context.Locais.FindAsync(localId);
                if (local != null) local.UsuariosVinculados += 1;

                await _context.SaveChangesAsync();
            }

            return RedirectToAction(nameof(Index));
        }

        public async Task<IActionResult> Detalhes(int id)
        {
            ViewBag.FotoUsuario = HttpContext.Session.GetString("FotoUsuario") ?? "/images/default-avatar.png";
            var local = await _context.Locais.FindAsync(id);

            if (local == null) return NotFound();
            return View(local);
        }

        [HttpPost]
        public async Task<IActionResult> Desvincular(int localId)
        {
            int usuarioId = HttpContext.Session.GetInt32("UsuarioId")!.Value;

            var vinculo = await _context.UsuariosLocais
                .FirstOrDefaultAsync(ul => ul.UsuarioId == usuarioId && ul.LocalId == localId);

            if (vinculo != null)
            {
                _context.UsuariosLocais.Remove(vinculo);

                var local = await _context.Locais.FindAsync(localId);
                if (local != null && local.UsuariosVinculados > 0) local.UsuariosVinculados -= 1;

                await _context.SaveChangesAsync();
            }

            return RedirectToAction(nameof(Index));
        }

        public IActionResult Add()
        {
            ViewBag.FotoUsuario = HttpContext.Session.GetString("FotoUsuario") ?? "/images/default-avatar.png";
            return View();
        }

        [HttpPost]
        public async Task<IActionResult> Criar(Local novoLocal, IFormFile Foto)
        {
            if (ModelState.IsValid)
            {
                if (Foto != null && Foto.Length > 0)
                {
                    var nomeArquivo =
                        Guid.NewGuid().ToString() + Path.GetExtension(Foto.FileName);

                    var pastaUploads = Path.Combine(
                        Directory.GetCurrentDirectory(),
                        "wwwroot",
                        "uploads",
                        "locais");

                    Directory.CreateDirectory(pastaUploads);

                    var caminhoSalvar = Path.Combine(
                        pastaUploads,
                        nomeArquivo);

                    using (var stream = new FileStream(caminhoSalvar, FileMode.Create))
                    {
                        await Foto.CopyToAsync(stream);
                    }

                    novoLocal.FotoUrl = "/uploads/locais/" + nomeArquivo;
                }
                else
                {
                    novoLocal.FotoUrl = "/images/default-local.jpg";
                }

                novoLocal.UsuariosVinculados = 1;
                _context.Locais.Add(novoLocal);
                await _context.SaveChangesAsync();

                int usuarioId = HttpContext.Session.GetInt32("UsuarioId")!.Value;
                _context.UsuariosLocais.Add(new UsuarioLocal { UsuarioId = usuarioId, LocalId = novoLocal.Id });
                await _context.SaveChangesAsync();

                return RedirectToAction(nameof(Index));
            }

            return View("Add");
        }

        [HttpPost]
        public async Task<IActionResult> VerificarDuplicidade(string cnpj)
        {
            if (string.IsNullOrEmpty(cnpj)) return BadRequest();

            var localExistente = await _context.Locais.FirstOrDefaultAsync(l => l.CNPJ == cnpj);
            if (localExistente != null)
            {
                return Json(new { duplicado = true, nomeLocal = localExistente.Nome });
            }
            return Json(new { duplicado = false });
        }
    }
}