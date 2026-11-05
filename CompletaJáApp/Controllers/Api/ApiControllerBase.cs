using System.IdentityModel.Tokens.Jwt;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CompletaJaApp.Controllers.Api
{
    /// <summary>
    /// Base dos controllers da API que exigem login.
    /// [Authorize] faz o ASP.NET responder 401 sozinho quando o token falta,
    /// é inválido ou expirou, antes mesmo de entrar no método.
    /// </summary>
    [ApiController]
    [Authorize]
    // O site exige token antiforgery em todo POST/PUT (filtro global no Program.cs).
    // A API não usa cookie: quem protege as chamadas aqui é o token JWT.
    [IgnoreAntiforgeryToken]
    public abstract class ApiControllerBase : ControllerBase
    {
        // Diferente do site, NÃO existe "?? 1" aqui: o id vem sempre do token.
        // Se chegamos neste ponto, o [Authorize] já garantiu um token válido,
        // e todo token emitido pelo TokenService tem o "sub".
        protected int UsuarioId => int.Parse(User.FindFirst(JwtRegisteredClaimNames.Sub)!.Value);

        // Mesmo padrão do site para quem não tem foto.
        protected const string AvatarPadrao = "/images/default-avatar.png";
    }
}
