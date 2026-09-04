using System.ComponentModel.DataAnnotations;

namespace CompletaJaApp.Models
{
    public class Usuario
    {
        [Key]
        public int Id { get; set; }

        [Required(ErrorMessage = "O nome é obrigatório.")]
        [MaxLength(100)]
        public string? Nome { get; set; }

        [Required(ErrorMessage = "O e-mail é obrigatório.")]
        [EmailAddress(ErrorMessage = "Por favor, digite um e-mail válido.")]
        [MaxLength(150)]
        public string? Email { get; set; }

        // Mudamos de 'Senha' para 'SenhaHash' para bater com o SQL
        [Required(ErrorMessage = "A senha é obrigatória.")]
        [MaxLength(255)]
        public string? SenhaHash { get; set; }

        [Required(ErrorMessage = "O CPF é obrigatório.")]
        [MaxLength(14)]
        public string? CPF { get; set; }

        // Mudamos de 'FotoPerfilUrl' para 'FotoUrl' para bater com o SQL
        [MaxLength(500)]
        public string? FotoUrl { get; set; }
    }
}