using System.ComponentModel.DataAnnotations;

namespace CompletaJaApp.Models
{
    /// <summary>
    /// Tabela associativa que define quais usuários colecionam quais álbuns do catálogo.
    /// </summary>
    public class UsuarioAlbum
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int UsuarioId { get; set; }

        [Required]
        public int AlbumId { get; set; }
    }
}