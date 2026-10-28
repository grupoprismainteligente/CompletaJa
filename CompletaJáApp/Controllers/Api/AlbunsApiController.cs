using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using CompletaJaApp.Data;
using CompletaJaApp.Models;

namespace CompletaJaApp.Controllers.Api
{
    [Route("api/albuns")]
    public class AlbunsApiController : ApiControllerBase
    {
        // Limite para não aceitar valores absurdos (ex.: 1000000 repetidas por engano).
        private const int QuantidadeMaxima = 99;

        // Tamanho da coluna Nome na tabela Figurinhas.
        private const int NomeMaximo = 100;

        private readonly CompletaJaContext _context;

        public AlbunsApiController(CompletaJaContext context)
        {
            _context = context;
        }

        // GET /api/albuns/meus
        [HttpGet("meus")]
        public async Task<ActionResult<List<AlbumDto>>> Meus()
        {
            var meusAlbunsIds = _context.UsuariosAlbuns
                .Where(ua => ua.UsuarioId == UsuarioId)
                .Select(ua => ua.AlbumId);

            return await _context.Albuns
                .Where(a => meusAlbunsIds.Contains(a.Id))
                .OrderByDescending(a => a.UsuariosVinculados)
                .Select(a => new AlbumDto(a.Id, a.Nome, a.CapaUrl, a.QuantidadeTotalFigurinhas, a.UsuariosVinculados))
                .ToListAsync();
        }

        // GET /api/albuns/catalogo
        [HttpGet("catalogo")]
        public async Task<ActionResult<List<AlbumCatalogoDto>>> Catalogo()
        {
            var meusAlbunsIds = await _context.UsuariosAlbuns
                .Where(ua => ua.UsuarioId == UsuarioId)
                .Select(ua => ua.AlbumId)
                .ToListAsync();

            var albuns = await _context.Albuns
                .OrderByDescending(a => a.UsuariosVinculados)
                .ToListAsync();

            return albuns
                .Select(a => new AlbumCatalogoDto(
                    a.Id, a.Nome, a.CapaUrl, a.QuantidadeTotalFigurinhas, a.UsuariosVinculados,
                    JaColeciona: meusAlbunsIds.Contains(a.Id)))
                .ToList();
        }

        // POST /api/albuns/{id}/vincular
        // Idempotente: chamar duas vezes não duplica o vínculo nem conta o usuário duas vezes.
        [HttpPost("{id:int}/vincular")]
        public async Task<IActionResult> Vincular(int id)
        {
            var album = await _context.Albuns.FindAsync(id);
            if (album == null) return NotFound(new { mensagem = "Álbum não encontrado." });

            bool jaVinculado = await _context.UsuariosAlbuns
                .AnyAsync(ua => ua.UsuarioId == UsuarioId && ua.AlbumId == id);

            if (!jaVinculado)
            {
                _context.UsuariosAlbuns.Add(new UsuarioAlbum { UsuarioId = UsuarioId, AlbumId = id });
                album.UsuariosVinculados += 1;
                await _context.SaveChangesAsync();
            }

            return NoContent();
        }

        // GET /api/albuns/{id}/figurinhas
        // Devolve a grade COMPLETA (1..total). O banco só tem linha das figurinhas que o
        // usuário já salvou; as outras saem com quantidade 0. Assim o app não precisa
        // saber a regra do código com 2 dígitos.
        [HttpGet("{id:int}/figurinhas")]
        public async Task<ActionResult<FigurinhasAlbumDto>> Figurinhas(int id)
        {
            var album = await _context.Albuns.FindAsync(id);
            if (album == null) return NotFound(new { mensagem = "Álbum não encontrado." });

            var salvas = await _context.Figurinhas
                .Where(f => f.AlbumId == id && f.UsuarioId == UsuarioId)
                .ToListAsync();

            // Mesmo critério da tela do site: se houver linha duplicada, vale a primeira.
            var porCodigo = salvas
                .GroupBy(f => f.Codigo)
                .ToDictionary(g => g.Key, g => g.First());

            int total = album.QuantidadeTotalFigurinhas;
            var grade = new List<FigurinhaDto>(total);

            for (int i = 1; i <= total; i++)
            {
                string codigo = FormatarCodigo(i);
                grade.Add(porCodigo.TryGetValue(codigo, out var f)
                    ? new FigurinhaDto(codigo, f.Nome ?? string.Empty, f.Quantidade)
                    : new FigurinhaDto(codigo, string.Empty, 0));
            }

            // Fórmulas iguais às do FigurinhaController do site.
            int unicas = salvas.Count(f => f.Quantidade > 0);
            int faltantes = Math.Max(0, total - unicas);
            int progresso = total > 0 ? (int)Math.Round((double)unicas / total * 100) : 0;

            return new FigurinhasAlbumDto(
                new AlbumResumoDto(album.Id, album.Nome, album.CapaUrl),
                total, unicas, faltantes, progresso, grade);
        }

        // PUT /api/albuns/{id}/figurinhas/{codigo}
        // Aceita "7" ou "07" na URL; grava sempre no formato do site ("07").
        [HttpPut("{id:int}/figurinhas/{codigo}")]
        public async Task<ActionResult<FigurinhaDto>> SalvarFigurinha(int id, string codigo, SalvarFigurinhaRequest request)
        {
            var album = await _context.Albuns.FindAsync(id);
            if (album == null) return NotFound(new { mensagem = "Álbum não encontrado." });

            if (!int.TryParse(codigo, out int numero) || numero < 1 || numero > album.QuantidadeTotalFigurinhas)
            {
                return BadRequest(new { mensagem = $"Código deve ser um número entre 1 e {album.QuantidadeTotalFigurinhas}." });
            }

            if (request.Quantidade < 0 || request.Quantidade > QuantidadeMaxima)
            {
                return BadRequest(new { mensagem = $"Quantidade deve estar entre 0 e {QuantidadeMaxima}." });
            }

            string? nome = request.Nome?.Trim();
            if (nome != null && nome.Length > NomeMaximo)
            {
                return BadRequest(new { mensagem = $"Nome pode ter no máximo {NomeMaximo} caracteres." });
            }

            string codigoFormatado = FormatarCodigo(numero);

            var figurinha = await _context.Figurinhas
                .FirstOrDefaultAsync(f => f.AlbumId == id && f.Codigo == codigoFormatado && f.UsuarioId == UsuarioId);

            if (figurinha == null)
            {
                figurinha = new Figurinha
                {
                    UsuarioId = UsuarioId,
                    AlbumId = id,
                    Codigo = codigoFormatado,
                    Nome = nome ?? string.Empty,
                    Quantidade = request.Quantidade
                };
                _context.Figurinhas.Add(figurinha);
            }
            else
            {
                // Regra do site: nome vazio NÃO apaga o nome que já existe.
                if (!string.IsNullOrEmpty(nome)) figurinha.Nome = nome;
                figurinha.Quantidade = request.Quantidade;
            }

            await _context.SaveChangesAsync();

            return new FigurinhaDto(figurinha.Codigo, figurinha.Nome ?? string.Empty, figurinha.Quantidade);
        }

        // Regra do site (Views/Figurinha/Index.cshtml): no mínimo 2 dígitos -> "01", "99", "100".
        private static string FormatarCodigo(int numero) => numero.ToString("D2");
    }
}
