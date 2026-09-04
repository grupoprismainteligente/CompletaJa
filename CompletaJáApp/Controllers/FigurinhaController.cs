using Microsoft.AspNetCore.Mvc;
using CompletaJaApp.Data;
using CompletaJaApp.Models;
using Microsoft.AspNetCore.Http;
using System.Linq;
using System;

namespace CompletaJáApp.Controllers
{
    public class FigurinhaController : Controller
    {
        private readonly CompletaJaContext _context;

        public FigurinhaController(CompletaJaContext context)
        {
            _context = context;
        }

        // ==========================================
        // 1. LISTAGEM ISOLADA DA COLEÇÃO
        // ==========================================
        [HttpGet]
        public IActionResult Index(int albumId)
        {
            ViewBag.FotoUsuario = HttpContext.Session.GetString("FotoUsuario") ?? "/images/default-avatar.png";
            int usuarioId = HttpContext.Session.GetInt32("UsuarioId")!.Value;

            var album = _context.Albuns.FirstOrDefault(a => a.Id == albumId);
            if (album == null) return RedirectToAction("Index", "Album");

            var figurinhas = _context.Figurinhas
                .Where(f => f.AlbumId == albumId && f.UsuarioId == usuarioId)
                .ToList();

            int totalDoAlbum = album.QuantidadeTotalFigurinhas;
            int figurinhasUnicas = figurinhas.Count(f => f.Quantidade > 0);
            int faltantes = totalDoAlbum - figurinhasUnicas;
            int progresso = totalDoAlbum > 0 ? (int)Math.Round((double)figurinhasUnicas / totalDoAlbum * 100) : 0;

            ViewBag.Album = album;
            ViewBag.TotalDoAlbum = totalDoAlbum;
            ViewBag.Unicas = figurinhasUnicas;
            ViewBag.Faltantes = faltantes;
            ViewBag.Progresso = progresso;

            return View(figurinhas);
        }

        // ==========================================
        // 2. SALVAMENTO DA FIGURINHA POR USUÁRIO (Otimizado)
        // ==========================================
        [HttpPost]
        public IActionResult Salvar(int AlbumId, string Codigo, string Nome, int Quantidade)
        {
            int usuarioId = HttpContext.Session.GetInt32("UsuarioId")!.Value;

            var figurinha = _context.Figurinhas
                .FirstOrDefault(f => f.AlbumId == AlbumId && f.Codigo == Codigo && f.UsuarioId == usuarioId);

            if (figurinha == null)
            {
                var novaFig = new Figurinha
                {
                    UsuarioId = usuarioId,
                    AlbumId = AlbumId,
                    Codigo = Codigo,
                    Nome = Nome,
                    Quantidade = Quantidade
                    // ImagemUrl não é mais utilizado/necessário
                };
                _context.Figurinhas.Add(novaFig);
            }
            else
            {
                figurinha.Nome = string.IsNullOrEmpty(Nome) ? figurinha.Nome : Nome;
                figurinha.Quantidade = Quantidade;
            }

            _context.SaveChanges();
            return RedirectToAction("Index", new { albumId = AlbumId });
        }
    }
}