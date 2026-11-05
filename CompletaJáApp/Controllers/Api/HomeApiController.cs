using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using CompletaJaApp.Data;

namespace CompletaJaApp.Controllers.Api
{
    [Route("api/home")]
    public class HomeApiController : ApiControllerBase
    {
        private readonly CompletaJaContext _context;

        public HomeApiController(CompletaJaContext context)
        {
            _context = context;
        }

        // GET /api/home
        // Mesmos cálculos do HomeController do site (parte "ESTATÍSTICAS DE COLEÇÃO").
        [HttpGet]
        public async Task<ActionResult<HomeDto>> Get()
        {
            var usuario = await _context.Usuarios.FindAsync(UsuarioId);

            // Token válido, mas o usuário foi apagado do banco: trata como sessão inválida.
            if (usuario == null) return Unauthorized();

            var minhasFigurinhas = await _context.Figurinhas
                .Where(f => f.UsuarioId == UsuarioId)
                .ToListAsync();

            // Repetidas: com 3 da mesma figurinha, 2 são repetidas.
            int repetidas = minhasFigurinhas
                .Where(f => f.Quantidade > 1)
                .Sum(f => f.Quantidade - 1);

            var meusAlbunsIds = await _context.UsuariosAlbuns
                .Where(ua => ua.UsuarioId == UsuarioId)
                .Select(ua => ua.AlbumId)
                .ToListAsync();

            // Igual ao site: sem vínculo registrado, deduz os álbuns pelas figurinhas que ele já tem.
            if (!meusAlbunsIds.Any() && minhasFigurinhas.Any())
            {
                meusAlbunsIds = minhasFigurinhas.Select(f => f.AlbumId).Distinct().ToList();
            }

            int totalCapacidade = await _context.Albuns
                .Where(a => meusAlbunsIds.Contains(a.Id))
                .SumAsync(a => a.QuantidadeTotalFigurinhas);

            int unicas = minhasFigurinhas.Count(f => f.Quantidade > 0 && meusAlbunsIds.Contains(f.AlbumId));

            int faltantes = Math.Max(0, totalCapacidade - unicas);

            return new HomeDto(
                usuario.Nome ?? string.Empty,
                usuario.FotoUrl ?? AvatarPadrao,
                repetidas,
                faltantes);
        }
    }
}
