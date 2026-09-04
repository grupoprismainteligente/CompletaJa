using Microsoft.AspNetCore.Mvc;
using CompletaJaApp.Data;
using CompletaJaApp.Models;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using System;

namespace CompletaJáApp.Controllers
{
    public class AlbumController : Controller
    {
        private readonly CompletaJaContext _context;
        private readonly IWebHostEnvironment _env;

        public AlbumController(CompletaJaContext context, IWebHostEnvironment env)
        {
            _context = context;
            _env = env;
        }

        // ==========================================
        // 1. MEUS ÁLBUNS (Index) - Apenas os vinculados
        // ==========================================
        public IActionResult Index()
        {
            ViewBag.FotoUsuario = HttpContext.Session.GetString("FotoUsuario") ?? "/images/default-avatar.png";
            int usuarioId = HttpContext.Session.GetInt32("UsuarioId")!.Value;

            var meusAlbunsIds = _context.UsuariosAlbuns
                .Where(ua => ua.UsuarioId == usuarioId)
                .Select(ua => ua.AlbumId)
                .ToList();

            var meusAlbuns = _context.Albuns
                .Where(a => meusAlbunsIds.Contains(a.Id))
                .OrderByDescending(a => a.UsuariosVinculados)
                .ToList();

            return View(meusAlbuns);
        }

        // ==========================================
        // 2. CATÁLOGO GLOBAL (Buscar) - Classificado por popularidade
        // ==========================================
        public IActionResult Buscar()
        {
            ViewBag.FotoUsuario = HttpContext.Session.GetString("FotoUsuario") ?? "/images/default-avatar.png";
            int usuarioId = HttpContext.Session.GetInt32("UsuarioId")!.Value;

            ViewBag.MeusAlbunsIds = _context.UsuariosAlbuns
                .Where(ua => ua.UsuarioId == usuarioId)
                .Select(ua => ua.AlbumId)
                .ToList();

            // CLASSIFICAÇÃO: Ordena do álbum com mais usuários vinculados para o menor
            var todosAlbuns = _context.Albuns
                .OrderByDescending(a => a.UsuariosVinculados)
                .ToList();

            return View(todosAlbuns);
        }

        // ==========================================
        // 3. VINCULAR USUÁRIO AO ÁLBUM EXISTENTE
        // ==========================================
        [HttpPost]
        public IActionResult Vincular(int albumId)
        {
            int usuarioId = HttpContext.Session.GetInt32("UsuarioId")!.Value;

            if (!_context.UsuariosAlbuns.Any(ua => ua.UsuarioId == usuarioId && ua.AlbumId == albumId))
            {
                _context.UsuariosAlbuns.Add(new UsuarioAlbum { UsuarioId = usuarioId, AlbumId = albumId });

                var album = _context.Albuns.Find(albumId);
                if (album != null) album.UsuariosVinculados += 1;

                _context.SaveChanges();
            }

            return RedirectToAction("Index");
        }

        // ==========================================
        // 4. FORMULÁRIO DE CADASTRO (Add)
        // ==========================================
        public IActionResult Add()
        {
            ViewBag.FotoUsuario = HttpContext.Session.GetString("FotoUsuario") ?? "/images/default-avatar.png";
            return View();
        }

        // ==========================================
        // 5. PROCESSA A CRIAÇÃO DO ÁLBUM GLOBAL
        // ==========================================
        [HttpPost]
        public async Task<IActionResult> Criar(string Nome, int TotalFigurinhas, IFormFile Capa)
        {
            if (string.IsNullOrWhiteSpace(Nome) || TotalFigurinhas <= 0 || Capa == null || Capa.Length == 0)
            {
                return RedirectToAction("Add");
            }

            string extensao = Path.GetExtension(Capa.FileName);
            string nomeArquivo = Guid.NewGuid().ToString() + extensao;
            string caminhoPasta = Path.Combine(_env.WebRootPath, "uploads", "albuns");

            if (!Directory.Exists(caminhoPasta)) Directory.CreateDirectory(caminhoPasta);

            string caminhoCompleto = Path.Combine(caminhoPasta, nomeArquivo);
            using (var stream = new FileStream(caminhoCompleto, FileMode.Create))
            {
                await Capa.CopyToAsync(stream);
            }

            var novoAlbum = new Album
            {
                Nome = Nome,
                QuantidadeTotalFigurinhas = TotalFigurinhas,
                CapaUrl = "/uploads/albuns/" + nomeArquivo,
                UsuariosVinculados = 1 // Nasce com 1 vínculo (o criador)
            };
            _context.Albuns.Add(novoAlbum);
            _context.SaveChanges();

            int usuarioId = HttpContext.Session.GetInt32("UsuarioId")!.Value;
            _context.UsuariosAlbuns.Add(new UsuarioAlbum { UsuarioId = usuarioId, AlbumId = novoAlbum.Id });
            _context.SaveChanges();

            return RedirectToAction("Index");
        }

        // ==========================================
        // 6. VALIDAÇÃO DE DUPLICIDADE (Algoritmo Restaurado)
        // ==========================================
        [HttpPost]
        public IActionResult VerificarDuplicidade(string nome, int quantidade)
        {
            if (string.IsNullOrWhiteSpace(nome) || quantidade <= 0)
                return Json(new { duplicado = false });

            var albunsMesmaQuantidade = _context.Albuns
                .Where(a => a.QuantidadeTotalFigurinhas == quantidade)
                .ToList();

            if (!albunsMesmaQuantidade.Any())
                return Json(new { duplicado = false });

            var palavrasNovoNome = nome.ToLower().Split(new[] { ' ' }, StringSplitOptions.RemoveEmptyEntries)
                                       .Where(p => p.Length > 2).ToList();

            foreach (var album in albunsMesmaQuantidade)
            {
                var palavrasAlbumBanco = album.Nome.ToLower().Split(new[] { ' ' }, StringSplitOptions.RemoveEmptyEntries)
                                             .Where(p => p.Length > 2).ToList();

                if (palavrasNovoNome.Intersect(palavrasAlbumBanco).Any())
                {
                    return Json(new { duplicado = true, nomeSemelhante = album.Nome });
                }
            }

            return Json(new { duplicado = false });
        }
    }
}