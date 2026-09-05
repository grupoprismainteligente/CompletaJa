using CompletaJaApp.Data;
using CompletaJaApp.Models;
using CompletaJaApp.Services;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using System;
using System.Linq;
using System.Threading.Tasks;

namespace CompletaJáApp.Controllers
{
    public class AlbumController : Controller
    {
        private readonly CompletaJaContext _context;
        private readonly ImagemService _imagemService;

        public AlbumController(
            CompletaJaContext context,
            ImagemService imagemService)
        {
            _context = context;
            _imagemService = imagemService;
        }

        // ==========================================
        // 1. MEUS ÁLBUNS
        // Mostra apenas os álbuns vinculados ao usuário
        // ==========================================
        public IActionResult Index()
        {
            ViewBag.FotoUsuario =
                HttpContext.Session.GetString("FotoUsuario")
                ?? "/images/default-avatar.png";

            int usuarioId =
                HttpContext.Session
                    .GetInt32("UsuarioId")!
                    .Value;

            var meusAlbunsIds =
                _context.UsuariosAlbuns
                    .Where(ua =>
                        ua.UsuarioId == usuarioId)
                    .Select(ua => ua.AlbumId)
                    .ToList();

            var meusAlbuns =
                _context.Albuns
                    .Where(a =>
                        meusAlbunsIds.Contains(a.Id))
                    .OrderByDescending(
                        a => a.UsuariosVinculados)
                    .ToList();

            return View(meusAlbuns);
        }

        // ==========================================
        // 2. CATÁLOGO GLOBAL
        // Mostra todos os álbuns existentes
        // ==========================================
        public IActionResult Buscar()
        {
            ViewBag.FotoUsuario =
                HttpContext.Session.GetString("FotoUsuario")
                ?? "/images/default-avatar.png";

            int usuarioId =
                HttpContext.Session
                    .GetInt32("UsuarioId")!
                    .Value;

            ViewBag.MeusAlbunsIds =
                _context.UsuariosAlbuns
                    .Where(ua =>
                        ua.UsuarioId == usuarioId)
                    .Select(ua => ua.AlbumId)
                    .ToList();

            var todosAlbuns =
                _context.Albuns
                    .OrderByDescending(
                        a => a.UsuariosVinculados)
                    .ToList();

            return View(todosAlbuns);
        }

        // ==========================================
        // 3. VINCULAR USUÁRIO A UM ÁLBUM EXISTENTE
        // ==========================================
        [HttpPost]
        public IActionResult Vincular(int albumId)
        {
            int usuarioId =
                HttpContext.Session
                    .GetInt32("UsuarioId")!
                    .Value;

            bool jaEstaVinculado =
                _context.UsuariosAlbuns.Any(
                    ua =>
                        ua.UsuarioId == usuarioId &&
                        ua.AlbumId == albumId);

            if (!jaEstaVinculado)
            {
                _context.UsuariosAlbuns.Add(
                    new UsuarioAlbum
                    {
                        UsuarioId = usuarioId,
                        AlbumId = albumId
                    });

                var album =
                    _context.Albuns.Find(albumId);

                if (album != null)
                {
                    album.UsuariosVinculados += 1;
                }

                _context.SaveChanges();
            }

            return RedirectToAction("Index");
        }

        // ==========================================
        // 4. EXIBE O FORMULÁRIO DE CADASTRO
        // ==========================================
        public IActionResult Add()
        {
            ViewBag.FotoUsuario =
                HttpContext.Session.GetString("FotoUsuario")
                ?? "/images/default-avatar.png";

            return View();
        }

        // ==========================================
        // 5. CRIA UM NOVO ÁLBUM
        // ==========================================
        [HttpPost]
        public async Task<IActionResult> Criar(
            string Nome,
            int TotalFigurinhas,
            IFormFile? Capa)
        {
            if (string.IsNullOrWhiteSpace(Nome) ||
                TotalFigurinhas <= 0 ||
                Capa == null ||
                Capa.Length == 0)
            {
                TempData["ErroUpload"] =
                    "Preencha os dados e selecione uma imagem para o álbum.";

                return RedirectToAction("Add");
            }

            string capaUrl;

            try
            {
                capaUrl =
                    await _imagemService.SalvarAsync(
                        Capa,
                        "albuns");
            }
            catch (InvalidOperationException ex)
            {
                TempData["ErroUpload"] =
                    ex.Message;

                return RedirectToAction("Add");
            }

            var novoAlbum = new Album
            {
                Nome = Nome,
                QuantidadeTotalFigurinhas =
                    TotalFigurinhas,
                CapaUrl = capaUrl,
                UsuariosVinculados = 1
            };

            _context.Albuns.Add(novoAlbum);
            _context.SaveChanges();

            int usuarioId =
                HttpContext.Session
                    .GetInt32("UsuarioId")!
                    .Value;

            _context.UsuariosAlbuns.Add(
                new UsuarioAlbum
                {
                    UsuarioId = usuarioId,
                    AlbumId = novoAlbum.Id
                });

            _context.SaveChanges();

            return RedirectToAction("Index");
        }

        // ==========================================
        // 6. VERIFICA SE JÁ EXISTE UM ÁLBUM PARECIDO
        // ==========================================
        [HttpPost]
        public IActionResult VerificarDuplicidade(
            string nome,
            int quantidade)
        {
            if (string.IsNullOrWhiteSpace(nome) ||
                quantidade <= 0)
            {
                return Json(
                    new
                    {
                        duplicado = false
                    });
            }

            var albunsMesmaQuantidade =
                _context.Albuns
                    .Where(a =>
                        a.QuantidadeTotalFigurinhas ==
                        quantidade)
                    .ToList();

            if (!albunsMesmaQuantidade.Any())
            {
                return Json(
                    new
                    {
                        duplicado = false
                    });
            }

            var palavrasNovoNome =
                nome.ToLower()
                    .Split(
                        new[] { ' ' },
                        StringSplitOptions.RemoveEmptyEntries)
                    .Where(p => p.Length > 2)
                    .ToList();

            foreach (var album in
                     albunsMesmaQuantidade)
            {
                var palavrasAlbumBanco =
                    album.Nome.ToLower()
                        .Split(
                            new[] { ' ' },
                            StringSplitOptions
                                .RemoveEmptyEntries)
                        .Where(p => p.Length > 2)
                        .ToList();

                bool possuiPalavraIgual =
                    palavrasNovoNome
                        .Intersect(palavrasAlbumBanco)
                        .Any();

                if (possuiPalavraIgual)
                {
                    return Json(
                        new
                        {
                            duplicado = true,
                            nomeSemelhante = album.Nome
                        });
                }
            }

            return Json(
                new
                {
                    duplicado = false
                });
        }
    }
}