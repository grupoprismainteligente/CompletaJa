using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace CompletaJaApp.Models
{
    /// <summary>
    /// Modela a posse e quantidade de figurinhas individuais por colecionador.
    /// </summary>
    public class Figurinha
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int Id { get; set; }

        [Required]
        public int UsuarioId { get; set; } // Identifica o dono do cromo

        [Required(ErrorMessage = "O código da figurinha é obrigatório.")]
        [MaxLength(20)]
        public string Codigo { get; set; } = string.Empty; // Ex: "10", "ARG-Messi"

        [MaxLength(100)]
        public string? Nome { get; set; } = string.Empty;

        public int Quantidade { get; set; } // 0 = Não tem, 1 = Colada, >1 = Repetida

        [MaxLength(500)]
        public string? ImagemUrl { get; set; } = "/images/default-sticker.png";

        [Required]
        public int AlbumId { get; set; }

        [ForeignKey("AlbumId")]
        public virtual Album? Album { get; set; }
    }
}