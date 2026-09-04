using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using CompletaJaApp.Data;
using CompletaJaApp.Models;
using System.Linq;
using System.Collections.Generic;

namespace CompletaJáApp.Controllers
{
    public class HomeController : Controller
    {
        private readonly CompletaJaContext _context;

        public HomeController(CompletaJaContext context)
        {
            _context = context;
        }

        public IActionResult Index()
        {
            int? meuId = HttpContext.Session.GetInt32("UsuarioId");
            string? nomeUsuario = HttpContext.Session.GetString("NomeUsuario");

            if (meuId == null || string.IsNullOrEmpty(nomeUsuario))
            {
                return RedirectToAction("Index", "Account");
            }

            // ====================================================================
            // 1. ESTATÍSTICAS DE COLEÇÃO (Repetidas e Faltantes Reais)
            // ====================================================================
            var minhasFigurinhas = _context.Figurinhas.Where(f => f.UsuarioId == meuId.Value).ToList();

            // Repetidas: Soma da sobra de cartas (Ex: Se tenho 3 da mesma, tenho 2 repetidas)
            int totalRepetidas = minhasFigurinhas.Where(f => f.Quantidade > 1).Sum(f => f.Quantidade - 1);

            // --- NOVA LÓGICA DE FALTANTES INTELIGENTE ---
            // a) Descobre quais álbuns o usuário coleciona (através da tabela de vínculos)
            var meusAlbunsIds = _context.UsuariosAlbuns
                .Where(ua => ua.UsuarioId == meuId.Value)
                .Select(ua => ua.AlbumId)
                .ToList();

            // Fallback de segurança: Caso o vínculo falhe, deduz pelos álbuns das figurinhas que ele já tem
            if (!meusAlbunsIds.Any() && minhasFigurinhas.Any())
            {
                meusAlbunsIds = minhasFigurinhas.Select(f => f.AlbumId).Distinct().ToList();
            }

            // b) Pega os álbuns completos no banco para ler as informações de capacidade
            var meusAlbuns = _context.Albuns.Where(a => meusAlbunsIds.Contains(a.Id)).ToList();

            // c) Soma o total de espaços disponíveis (capacidade) de todos os álbuns iniciados
            int totalCapacidade = meusAlbuns.Sum(a => a.QuantidadeTotalFigurinhas);

            // d) Conta quantas figurinhas ÚNICAS o usuário já colou nesses álbuns (Quantidade > 0)
            int totalUnicasPossuidas = minhasFigurinhas.Count(f => f.Quantidade > 0 && meusAlbunsIds.Contains(f.AlbumId));

            // e) Calcula o que falta de forma matemática e segura
            int totalFaltantes = totalCapacidade - totalUnicasPossuidas;
            if (totalFaltantes < 0) totalFaltantes = 0; // Trava contra números negativos por segurança

            ViewBag.Repetidas = totalRepetidas;
            ViewBag.Faltantes = totalFaltantes;

            // ====================================================================
            // 2. MATCHES/CONVERSAS RECENTES
            // ====================================================================
            var contatosIds = _context.Mensagens
                .Where(m => m.RemetenteId == meuId.Value || m.DestinatarioId == meuId.Value)
                .OrderByDescending(m => m.DataEnvio)
                .Select(m => m.RemetenteId == meuId.Value ? m.DestinatarioId : m.RemetenteId)
                .Distinct()
                .Take(5)
                .ToList();

            var matchesRecentes = new List<MatchDashboardViewModel>();

            foreach (var contatoId in contatosIds)
            {
                var usuarioOutro = _context.Usuarios.Find(contatoId);
                if (usuarioOutro != null)
                {
                    matchesRecentes.Add(new MatchDashboardViewModel
                    {
                        UsuarioId = usuarioOutro.Id,
                        Nome = usuarioOutro.Nome,
                        FotoUrl = usuarioOutro.FotoUrl ?? "/images/default-avatar.png",
                        TotalMensagens = _context.Mensagens.Count(m =>
                            (m.RemetenteId == meuId.Value && m.DestinatarioId == contatoId) ||
                            (m.RemetenteId == contatoId && m.DestinatarioId == meuId.Value))
                    });
                }
            }

            return View(matchesRecentes);
        }

        public IActionResult Sair()
        {
            HttpContext.Session.Clear();
            return RedirectToAction("Index", "Account");
        }
    }

    // ViewModel auxiliar para carregar os dados para a tela
    public class MatchDashboardViewModel
    {
        public int UsuarioId { get; set; }
        public string? Nome { get; set; }
        public string? FotoUrl { get; set; }
        public int TotalMensagens { get; set; }
    }
}