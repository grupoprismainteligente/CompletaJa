using System.ComponentModel.DataAnnotations;

namespace CompletaJaApp.Models
{
    /// <summary>
    /// Representa os pontos físicos de troca cadastrados globalmente na plataforma.
    /// </summary>
    public class Local
    {
        [Key]
        public int Id { get; set; }

        [Required(ErrorMessage = "O nome do local é obrigatório.")]
        [MaxLength(100)]
        public string Nome { get; set; } = string.Empty;

        [Required(ErrorMessage = "O CNPJ é obrigatório.")]
        [MaxLength(20)]
        public string CNPJ { get; set; } = string.Empty;

        [Required(ErrorMessage = "O tipo de estabelecimento é obrigatório.")]
        [MaxLength(50)]
        public string Tipo { get; set; } = string.Empty; // Ex: Shopping, Banca

        [Required(ErrorMessage = "O endereço é obrigatório.")]
        [MaxLength(255)]
        public string Endereco { get; set; } = string.Empty;

        [Required(ErrorMessage = "A descrição da área de troca é obrigatória.")]
        [MaxLength(255)]
        public string AreaTroca { get; set; } = string.Empty;

        [MaxLength(500)]
        public string? FotoUrl { get; set; } = "/images/default-local.jpg";

        public int UsuariosVinculados { get; set; } = 0; // Controle de popularidade
    }
}