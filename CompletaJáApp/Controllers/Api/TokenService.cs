using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Microsoft.IdentityModel.Tokens;
using CompletaJaApp.Models;

namespace CompletaJaApp.Controllers.Api
{
    /// <summary>
    /// Gera os tokens JWT entregues ao app no login.
    /// Registrado como singleton no Program.cs, que também usa a MESMA chave
    /// e os mesmos Issuer/Audience para validar o token nas próximas chamadas.
    /// </summary>
    public class TokenService
    {
        // Identificam quem emitiu o token e para quem ele serve.
        // Um token de outro sistema assinado com outra chave já seria recusado;
        // isso é só uma camada a mais de conferência.
        public const string Issuer = "CompletaJaApi";
        public const string Audience = "CompletaJaMobile";

        // Sem refresh token na V1: o usuário fica logado por 30 dias e depois
        // o app recebe 401 e volta para a tela de login.
        private static readonly TimeSpan Validade = TimeSpan.FromDays(30);

        private readonly SymmetricSecurityKey _chave;

        public TokenService(SymmetricSecurityKey chave)
        {
            _chave = chave;
        }

        public string GerarToken(Usuario usuario)
        {
            // "sub" (subject) é o campo padrão do JWT para "de quem é este token".
            // É daqui que a API tira o id do usuário em todas as chamadas.
            var claims = new[]
            {
                new Claim(JwtRegisteredClaimNames.Sub, usuario.Id.ToString()),
                new Claim(JwtRegisteredClaimNames.Name, usuario.Nome ?? string.Empty)
            };

            var token = new JwtSecurityToken(
                issuer: Issuer,
                audience: Audience,
                claims: claims,
                expires: DateTime.UtcNow.Add(Validade),
                signingCredentials: new SigningCredentials(_chave, SecurityAlgorithms.HmacSha256));

            return new JwtSecurityTokenHandler().WriteToken(token);
        }
    }
}
