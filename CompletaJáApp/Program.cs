// Importando as pastas que precisamos (coloque no topo do arquivo)
using Microsoft.EntityFrameworkCore;
using CompletaJaApp.Data;
using CompletaJaApp.Hubs; // ADICIONADO 1: Importa a pasta do seu ChatHub
using Microsoft.AspNetCore.Identity;
using CompletaJaApp.Models;
using Microsoft.AspNetCore.Http;
using CompletaJaApp.Services;
using Microsoft.AspNetCore.Http.Features;

var builder = WebApplication.CreateBuilder(args);

// 1. ADICIONANDO OS SERVIÇOS
builder.Services.AddControllersWithViews();
builder.Services.AddScoped<IPasswordHasher<Usuario>, PasswordHasher<Usuario>>();
builder.Services.AddScoped<ImagemService>();

builder.Services.Configure<FormOptions>(options =>
{
    options.MultipartBodyLengthLimit = 6 * 1024 * 1024;
});

// Configurando a conexão com o Banco de Dados SQL Server
builder.Services.AddDbContext<CompletaJaContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

// Habilita a memória (Sessão) para o nosso sistema de Login
builder.Services.AddSession();

// ADICIONADO 2: Habilita o motor do SignalR (tempo real) no servidor
builder.Services.AddSignalR();

var app = builder.Build();

// 2. CONFIGURANDO O COMPORTAMENTO DO SITE
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();
app.UseRouting();

// Ativa a Sessão de fato (Aviso: tem que ficar exatamente aqui!)
app.UseSession();

// Protege todas as páginas internas do sistema.
// Somente as páginas da conta permanecem públicas.
app.Use(async (context, next) =>
{
    var caminho = context.Request.Path;

    bool rotaPublica =
        caminho.StartsWithSegments("/Account") ||
        caminho.StartsWithSegments("/Home/Error");

    bool usuarioEstaLogado =
        context.Session.GetInt32("UsuarioId").HasValue;

    if (!rotaPublica && !usuarioEstaLogado)
    {
        context.Response.Redirect("/Account/Index");
        return;
    }

    await next();
});

app.UseAuthorization();

// 3. CONFIGURANDO A TELA INICIAL
// Mudamos aqui para o site abrir direto no Account (Login) ao invés do Home
app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Account}/{action=Index}/{id?}");

// ADICIONADO 3: Cria a rota que o JavaScript vai usar para conectar no Chat
app.MapHub<ChatHub>("/chatHub");

app.Run();