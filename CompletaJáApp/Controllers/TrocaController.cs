using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Http;
using CompletaJaApp.Data;
using CompletaJaApp.Models;
using System.Linq;
using System.Collections.Generic;
using System;

namespace CompletaJáApp.Controllers
{
    public class TrocaController : Controller
    {
        private readonly CompletaJaContext _context;

        public TrocaController(CompletaJaContext context)
        {
            _context = context;
        }

        public IActionResult Index()
        {
            ViewBag.FotoUsuario = HttpContext.Session.GetString("FotoUsuario") ?? "/images/default-avatar.png";
            int meuId = HttpContext.Session.GetInt32("UsuarioId")!.Value;

            // 1. Descobrir quais locais eu frequento
            var meusLocaisIds = _context.UsuariosLocais
                .Where(ul => ul.UsuarioId == meuId)
                .Select(ul => ul.LocalId)
                .ToList();

            // 2. Achar outros usuários nos mesmos locais
            var outrosUsuariosIds = _context.UsuariosLocais
                .Where(ul => meusLocaisIds.Contains(ul.LocalId) && ul.UsuarioId != meuId)
                .Select(ul => ul.UsuarioId)
                .Distinct()
                .ToList();

            // 3. Minhas Figurinhas e Álbuns
            var minhasFigurinhas = _context.Figurinhas.Where(f => f.UsuarioId == meuId).ToList();

            // O que eu tenho repetido para oferecer (Minha Moeda de Troca)
            var minhasRepetidas = minhasFigurinhas.Where(f => f.Quantidade > 1).ToList();

            // O que eu já possuo (Para o sistema saber que eu NÃO preciso mais dessas)
            var euJaPossuo = minhasFigurinhas.Where(f => f.Quantidade > 0).ToList();

            // Álbuns que eu coleciono (Deduzido pelas figurinhas que eu já possuo)
            var meusAlbunsIds = minhasFigurinhas.Select(f => f.AlbumId).Distinct().ToList();

            var matchesParaExibir = new List<MatchViewModel>();

            foreach (var outroId in outrosUsuariosIds)
            {
                var figOutro = _context.Figurinhas.Where(f => f.UsuarioId == outroId).ToList();

                var repetidasDele = figOutro.Where(f => f.Quantidade > 1).ToList();
                var eleJaPossui = figOutro.Where(f => f.Quantidade > 0).ToList();
                var albunsDele = figOutro.Select(f => f.AlbumId).Distinct().ToList();

                // O que ELE me oferece?
                // (Ele tem repetida, de um álbum que EU também coleciono, e que EU NÃO tenho na minha coleção)
                var eleMeOferece = repetidasDele
                    .Where(ele => meusAlbunsIds.Contains(ele.AlbumId) &&
                                  !euJaPossuo.Any(eu => eu.AlbumId == ele.AlbumId && eu.Codigo == ele.Codigo))
                    .ToList();

                // O que EU ofereço para ele?
                // (Eu tenho repetida, de um álbum que ELE também coleciona, e que ELE NÃO tem na coleção dele)
                var elePrecisaDeMim = minhasRepetidas
                    .Where(eu => albunsDele.Contains(eu.AlbumId) &&
                                 !eleJaPossui.Any(ele => ele.AlbumId == eu.AlbumId && ele.Codigo == eu.Codigo))
                    .ToList();

                // Se a troca for mútua (temos figurinhas um pro outro), GERA O MATCH!
                if (eleMeOferece.Any() && elePrecisaDeMim.Any())
                {
                    var usuarioOutro = _context.Usuarios.Find(outroId);

                    // Acha o local específico onde os dois se cruzam
                    var localComum = _context.Locais.FirstOrDefault(l =>
                        _context.UsuariosLocais.Any(ul => ul.UsuarioId == outroId && ul.LocalId == l.Id) &&
                        meusLocaisIds.Contains(l.Id));

                    // --- MÁGICA: CÁLCULO DE MATCH PROPORCIONAL E JUSTO ---
                    int qtdEleMeOferece = eleMeOferece.Count; // O que ele tem que EU preciso
                    int qtdEuOfereco = elePrecisaDeMim.Count; // O que eu tenho que ELE precisa

                    int percentualCalculado = 0;

                    // 1. Se as quantidades forem exatamente iguais (ex: 2 pra lá, 2 pra cá)
                    if (qtdEleMeOferece == qtdEuOfereco)
                    {
                        percentualCalculado = 100;
                    }
                    // 2. Caso EU tenha mais figurinhas do que ele tem pra mim
                    else if (qtdEuOfereco > qtdEleMeOferece)
                    {
                        percentualCalculado = (int)Math.Round(((double)qtdEleMeOferece / qtdEuOfereco) * 100);
                    }
                    // 3. Caso ELE tenha mais figurinhas do que eu tenho pra ele
                    else
                    {
                        percentualCalculado = (int)Math.Round(((double)qtdEuOfereco / qtdEleMeOferece) * 100);
                    }
                    // -----------------------------------------------------

                    matchesParaExibir.Add(new MatchViewModel
                    {
                        UsuarioId = outroId,
                        Nome = usuarioOutro?.Nome ?? "Usuário",
                        FotoUrl = usuarioOutro?.FotoUrl ?? "/images/default-avatar.png",
                        LocalNome = localComum?.Nome ?? "Ponto de Encontro",
                        FigurinhasParaMim = eleMeOferece,
                        FigurinhasParaEle = elePrecisaDeMim,
                        PercentualMatch = percentualCalculado
                    });
                }
            }

            return View(matchesParaExibir);
        }
    }

    // CORREÇÃO: Inicialização padrão de listas e marcação de strings como Nullable (?)
    public class MatchViewModel
    {
        public int UsuarioId { get; set; }
        public string? Nome { get; set; }
        public string? FotoUrl { get; set; }
        public string? LocalNome { get; set; }
        public int PercentualMatch { get; set; }
        public List<Figurinha> FigurinhasParaMim { get; set; } = new List<Figurinha>();
        public List<Figurinha> FigurinhasParaEle { get; set; } = new List<Figurinha>();
    }
}