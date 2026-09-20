using Microsoft.EntityFrameworkCore;
using CompletaJaApp.Data;
using CompletaJaApp.Hubs;
using Microsoft.AspNetCore.Identity;
using CompletaJaApp.Models;
using Microsoft.AspNetCore.Http;
using CompletaJaApp.Services;
using Microsoft.AspNetCore.Http.Features;

var builder = WebApplication.CreateBuilder(args);

// 1. ADICIONANDO OS SERVIÇOS
builder.Services.AddControllersWithViews();

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
builder.Services.AddSession();

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

app.UseSession();

// Protege todas as páginas internas.
// Somente as páginas da conta permanecem públicas.
app.Use(async (context, next) =>
{
    var caminho = context.Request.Path;

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