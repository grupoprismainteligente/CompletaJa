using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace CompletaJaApp.Models
{
    /// <summary>
    /// Model Global que representa o catálogo de álbuns disponíveis na plataforma.
    /// Contém o contador de popularidade para ordenação no catálogo.
    /// </summary>
    public class Album
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int Id { get; set; }

        [Required(ErrorMessage = "O nome do álbum é obrigatório.")]
        [MaxLength(100)]
        public string Nome { get; set; } = string.Empty;

        [Column("TotalFigurinhas")]
        [Required(ErrorMessage = "A quantidade total de figurinhas é obrigatória.")]
        public int QuantidadeTotalFigurinhas { get; set; }

        [MaxLength(500)]
        public string CapaUrl { get; set; } = "/images/default-album.png";

        // ADICIONADO: Controla quantos colecionadores estão ativos neste álbum para fins de classificação
        public int UsuariosVinculados { get; set; } = 0;
    }
}