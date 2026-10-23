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

var builder = WebApplication.CreateBuilder(args);

// 1. ADICIONANDO OS SERVIÇOS
// CSRF: exige o token antiforgery em TODA requisição POST/PUT/DELETE
// de formulários e chamadas fetch (GET/HEAD/OPTIONS ficam isentos).
builder.Services.AddControllersWithViews(options =>
{
    options.Filters.Add(new AutoValidateAntiforgeryTokenAttribute());
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

app.UseRateLimiter();

app.UseSession();

// Protege todas as páginas internas.
// Somente as páginas da conta permanecem públicas.
app.Use(async (context, next) =>
{
    var caminho = context.Request.Path;

    // Páginas dinâmicas não ficam no cache do navegador: depois do
    // logout, o botão "voltar" do navegador não mostra telas internas.
    context.Response.Headers["Cache-Control"] = "no-store, no-cache, must-revalidate";
    context.Response.Headers["Pragma"] = "no-cache";

    bool rotaPublica =
        caminho.StartsWithSegments("/Account") ||
        caminho.StartsWithSegments("/Home/Error");

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