using Microsoft.EntityFrameworkCore;
using CompletaJaApp.Data;
using CompletaJaApp.Hubs;
using Microsoft.AspNetCore.Identity;
using CompletaJaApp.Models;
using Microsoft.AspNetCore.Http;
using CompletaJaApp.Services;
using Microsoft.AspNetCore.Http.Features;
using Microsoft.AspNetCore.Mvc;
using System.Threading.RateLimiting;
using System.Security.Cryptography;
using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using CompletaJaApp.Controllers.Api;

var builder = WebApplication.CreateBuilder(args);

// 1. ADICIONANDO OS SERVIÇOS
// CSRF: exige o token antiforgery em TODA requisição POST/PUT/DELETE
// de formulários e chamadas fetch (GET/HEAD/OPTIONS ficam isentos).
builder.Services.AddControllersWithViews(options =>
{
    options.Filters.Add(new AutoValidateAntiforgeryTokenAttribute());
})
// Só afeta os controllers com [ApiController] (a API do app): corpo ausente ou JSON
// malformado respondem no mesmo formato dos demais erros da API, { "mensagem": "..." }.
.ConfigureApiBehaviorOptions(options =>
{
    options.InvalidModelStateResponseFactory = _ =>
        new BadRequestObjectResult(new { mensagem = "Requisição inválida. Confira os dados enviados." });
});

builder.Services.AddAntiforgery(options =>
{
    // Nome do cabeçalho usado pelas chamadas fetch (ver _Layout.cshtml)
    options.HeaderName = "RequestVerificationToken";
    options.Cookie.HttpOnly = true;
    options.Cookie.SameSite = SameSiteMode.Strict;
    options.Cookie.SecurePolicy = CookieSecurePolicy.SameAsRequest;
});

// Limite de requisições por IP nas rotas sensíveis (força bruta / spam de e-mail)
builder.Services.AddRateLimiter(options =>
{
    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;

    options.AddPolicy("login", httpContext =>
        RateLimitPartition.GetFixedWindowLimiter(
            httpContext.Connection.RemoteIpAddress?.ToString() ?? "desconhecido",
            _ => new FixedWindowRateLimiterOptions
            {
                PermitLimit = 10,
                Window = TimeSpan.FromMinutes(1),
                QueueLimit = 0
            }));

    options.AddPolicy("recuperacao", httpContext =>
        RateLimitPartition.GetFixedWindowLimiter(
            httpContext.Connection.RemoteIpAddress?.ToString() ?? "desconhecido",
            _ => new FixedWindowRateLimiterOptions
            {
                PermitLimit = 5,
                Window = TimeSpan.FromMinutes(10),
                QueueLimit = 0
            }));
});

// Bloqueio temporário por e-mail após várias senhas erradas
builder.Services.AddSingleton<LoginAttemptService>();

// Envio de e-mail (recuperação de senha). Configurado por variáveis Smtp__*
builder.Services.AddScoped<IEmailService, SmtpEmailService>();

builder.Services.AddScoped<
    IPasswordHasher<Usuario>,
    PasswordHasher<Usuario>>();

builder.Services.AddScoped<ImagemService>();

builder.Services.Configure<FormOptions>(options =>
{
    // O limite real de cada imagem continua sendo
    // 5 MB e é validado pelo ImagemService.
    options.MultipartBodyLengthLimit =
        10 * 1024 * 1024;
});

// Configurando a conexão com o Banco de Dados
builder.Services.AddDbContext<CompletaJaContext>(
    options =>
        options.UseSqlServer(
            builder.Configuration
                .GetConnectionString(
                    "DefaultConnection"),
            sqlServerOptions =>
                sqlServerOptions
                    .EnableRetryOnFailure()));

// Habilita a Sessão
builder.Services.AddSession(options =>
{
    options.Cookie.HttpOnly = true;
    options.Cookie.SameSite = SameSiteMode.Lax;
    options.Cookie.SecurePolicy = CookieSecurePolicy.SameAsRequest;
    options.Cookie.IsEssential = true;
    options.IdleTimeout = TimeSpan.FromMinutes(30);
});

// Habilita o SignalR
builder.Services.AddSignalR();

// Só em desenvolvimento: libera o app Flutter rodando no Chrome (porta aleatória de
// localhost) a chamar a API local. O APK não passa por CORS, que é regra de navegador.
if (builder.Environment.IsDevelopment())
{
    builder.Services.AddCors(options =>
        options.AddDefaultPolicy(policy =>
            policy.SetIsOriginAllowed(origem => new Uri(origem).IsLoopback)
                .AllowAnyHeader()
                .AllowAnyMethod()));
}

// API DO APP MOBILE: autenticação por token JWT.
// Só os controllers de Controllers/Api usam isso ([Authorize]); o site continua com Sessão.
// A chave vem de configuração: user-secrets na máquina local, variável de ambiente
// Jwt__Key no Render. Nunca colocar a chave no código nem no appsettings.json.
var jwtKey = builder.Configuration["Jwt:Key"];
if (string.IsNullOrWhiteSpace(jwtKey))
{
    // Sem chave configurada o SITE não pode cair por causa da API. Usamos uma chave
    // aleatória só desta execução: o login do app funciona, mas os tokens deixam de
    // valer quando o servidor reinicia. Configure Jwt:Key para tokens duradouros.
    jwtKey = Convert.ToBase64String(RandomNumberGenerator.GetBytes(48));
    Console.WriteLine("AVISO: Jwt:Key não configurada. Usando chave temporária para a API.");
}
else if (Encoding.UTF8.GetByteCount(jwtKey) < 32)
{
    // O algoritmo HS256 exige chave de pelo menos 256 bits (32 bytes).
    throw new InvalidOperationException("Jwt:Key precisa ter pelo menos 32 caracteres.");
}
var chaveJwt = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey));
builder.Services.AddSingleton(new TokenService(chaveJwt));

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        // Mantém o nome original das claims ("sub"), que é o que a API lê.
        options.MapInboundClaims = false;

        // 401 também em JSON { "mensagem": "..." }, igual aos outros erros da API.
        options.Events = new JwtBearerEvents
        {
            OnChallenge = async context =>
            {
                context.HandleResponse(); // impede a resposta vazia padrão
                context.Response.StatusCode = StatusCodes.Status401Unauthorized;
                await context.Response.WriteAsJsonAsync(new { mensagem = "Sessão inválida ou expirada. Entre novamente." });
            }
        };

        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidIssuer = TokenService.Issuer,
            ValidateAudience = true,
            ValidAudience = TokenService.Audience,
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = chaveJwt,
            ValidateLifetime = true,
            ClockSkew = TimeSpan.FromMinutes(1)
        };
    });

var app = builder.Build();

// Cria o banco e aplica as migrations pendentes.
// Se todas já estiverem aplicadas, nenhuma alteração é feita.
using (var scope = app.Services.CreateScope())
{
    var context =
        scope.ServiceProvider
            .GetRequiredService<CompletaJaContext>();

    await context.Database.MigrateAsync();
}

// 2. CONFIGURANDO O COMPORTAMENTO DO SITE
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();
app.UseRouting();

if (app.Environment.IsDevelopment())
{
    app.UseCors();
}

app.UseRateLimiter();

app.UseSession();

// API do app: lê o token JWT (tem que vir antes do UseAuthorization).
app.UseAuthentication();

// Protege todas as páginas internas.
// Somente as páginas da conta permanecem públicas.
app.Use(async (context, next) =>
{
    var caminho = context.Request.Path;

    // Páginas dinâmicas não ficam no cache do navegador: depois do
    // logout, o botão "voltar" do navegador não mostra telas internas.
    context.Response.Headers["Cache-Control"] = "no-store, no-cache, must-revalidate";
    context.Response.Headers["Pragma"] = "no-cache";

    // /api não usa sessão: quem protege é o [Authorize] com JWT de cada controller
    // (responde 401 em JSON, em vez de redirecionar para a página de login).
    bool rotaPublica =
        caminho.StartsWithSegments("/Account") ||
        caminho.StartsWithSegments("/Home/Error") ||
        caminho.StartsWithSegments("/api");

    bool usuarioEstaLogado =
        context.Session
            .GetInt32("UsuarioId")
            .HasValue;

    if (!rotaPublica &&
        !usuarioEstaLogado)
    {
        context.Response.Redirect(
            "/Account/Index");

        return;
    }

    await next();
});

app.UseAuthorization();

// 3. CONFIGURANDO A TELA INICIAL
app.MapControllerRoute(
    name: "default",
    pattern:
        "{controller=Account}/{action=Index}/{id?}");

// Rota do SignalR
app.MapHub<ChatHub>("/chatHub");

app.Run();