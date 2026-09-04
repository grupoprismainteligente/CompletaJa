using System.ComponentModel.DataAnnotations;

namespace CompletaJaApp.Models
{
    /// <summary>
    /// Tabela associativa para mapear em quais estabelecimentos o usuário costuma trocar figurinhas.
    /// </summary>
    public class UsuarioLocal
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int UsuarioId { get; set; }

        [Required]
        public int LocalId { get; set; }
    }
}