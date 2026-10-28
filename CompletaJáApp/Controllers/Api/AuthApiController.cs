using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;
using CompletaJaApp.Data;
using CompletaJaApp.Models;
using CompletaJaApp.Services;

namespace CompletaJaApp.Controllers.Api
{
    [ApiController]
    [Route("api/auth")]
    // O site exige token antiforgery em todo POST/PUT (filtro global no Program.cs).
    // O app mobile não tem cookie nem formulário, a proteção dele é o token JWT.
    [IgnoreAntiforgeryToken]
    public class AuthApiController : ControllerBase
    {
        private readonly CompletaJaContext _context;
        private readonly TokenService _tokenService;
        private readonly IPasswordHasher<Usuario> _passwordHasher;
        private readonly LoginAttemptService _tentativas;

        public AuthApiController(
            CompletaJaContext context,
            TokenService tokenService,
            IPasswordHasher<Usuario> passwordHasher,
            LoginAttemptService tentativas)
        {
            _context = context;
            _tokenService = tokenService;
            _passwordHasher = passwordHasher;
            _tentativas = tentativas;
        }

        // POST /api/auth/login
        // Mesmas proteções do login do site: limite por IP e bloqueio por e-mail.
        [HttpPost("login")]
        [EnableRateLimiting("login")]
        public async Task<ActionResult<LoginResponse>> Login(LoginRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.Email) || string.IsNullOrEmpty(request.Senha))
            {
                return BadRequest(new { mensagem = "Preencha e-mail e senha." });
            }

            // Teclado de celular costuma colocar espaço no fim do e-mail; a senha não é mexida.
            var email = request.Email.Trim();

            if (_tentativas.EstaBloqueado(email, out var minutos))
            {
                return StatusCode(StatusCodes.Status429TooManyRequests,
                    new { mensagem = $"Muitas tentativas de login. Tente novamente em {minutos} minuto(s)." });
            }

            // Busca só pelo e-mail: com hash, a senha não dá para comparar dentro do SQL.
            var usuario = await _context.Usuarios.FirstOrDefaultAsync(u => u.Email == email);

            if (usuario == null || !SenhaConfere(usuario, request.Senha))
            {
                _tentativas.RegistrarFalha(email);
                return Unauthorized(new { mensagem = "E-mail ou senha inválidos." });
            }

            _tentativas.Limpar(email);

            var token = _tokenService.GerarToken(usuario);
            var dto = new UsuarioDto(usuario.Id, usuario.Nome ?? string.Empty, usuario.FotoUrl ?? "/images/default-avatar.png");

            return new LoginResponse(token, dto);
        }

        // O banco guarda a senha como hash do ASP.NET Identity (PasswordHasher), igual ao site.
        // Se a SenhaHash não for um hash válido, o Identity lança FormatException: tratamos como senha errada.
        private bool SenhaConfere(Usuario usuario, string senhaDigitada)
        {
            PasswordVerificationResult resultado;
            try
            {
                resultado = _passwordHasher.VerifyHashedPassword(
                    usuario, usuario.SenhaHash ?? string.Empty, senhaDigitada);
            }
            catch (FormatException)
            {
                return false;
            }

            if (resultado == PasswordVerificationResult.Failed)
            {
                return false;
            }

            // Hash gerado com parâmetros antigos: regrava com o padrão atual, como o site faz.
            if (resultado == PasswordVerificationResult.SuccessRehashNeeded)
            {
                usuario.SenhaHash = _passwordHasher.HashPassword(usuario, senhaDigitada);
                _context.SaveChanges();
            }

            return true;
        }
    }
}
