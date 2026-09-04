using System;

namespace CompletaJaApp.Models
{
    public class Mensagem
    {
        public int Id { get; set; }
        public int RemetenteId { get; set; }
        public int DestinatarioId { get; set; }

        // Adicionado o ? para corrigir o erro de valor não nulo
        public string? Texto { get; set; }

        public DateTime DataEnvio { get; set; } = DateTime.Now;
    }
}