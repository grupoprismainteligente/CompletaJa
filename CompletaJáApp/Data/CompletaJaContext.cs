using Microsoft.EntityFrameworkCore;
using CompletaJaApp.Models;

namespace CompletaJaApp.Data
{
    /// <summary>
    /// Contexto central do Entity Framework Core.
    /// Mapeia todas as tabelas principais e associativas no SQL Server.
    /// </summary>
    public class CompletaJaContext : DbContext
    {
        public CompletaJaContext(DbContextOptions<CompletaJaContext> options) : base(options)
        {
        }

        // Tabelas de Entidades Globais
        public DbSet<Usuario> Usuarios { get; set; }
        public DbSet<Album> Albuns { get; set; }
        public DbSet<Local> Locais { get; set; }

        // Tabelas de Posse e Vínculos por Usuário
        public DbSet<Figurinha> Figurinhas { get; set; }
        public DbSet<UsuarioAlbum> UsuariosAlbuns { get; set; }
        public DbSet<UsuarioLocal> UsuariosLocais { get; set; }

        // Tabela de Comunicação entre Colecionadores
        public DbSet<Mensagem> Mensagens { get; set; }
    }
}