using System;
using System.ComponentModel.DataAnnotations;
using Microsoft.EntityFrameworkCore;

namespace CompletaJaApp.Models
{
    // Pedido de recuperação de senha.
    // Guardamos apenas o HASH (SHA-256) do token: se o banco vazar,
    // os links de redefinição não podem ser reconstruídos.
    [Index(nameof(TokenHash), IsUnique = true)]
    public class RedefinicaoSenha
    {
        [Key]
        public int Id { get; set; }

        public int UsuarioId { get; set; }

        [Required]
        [MaxLength(64)]
        public string TokenHash { get; set; } = string.Empty;

        public DateTime ExpiraEm { get; set; }

        public bool Usado { get; set; }
    }
}
