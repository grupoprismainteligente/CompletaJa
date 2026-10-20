using System;
using System.Collections.Concurrent;

namespace CompletaJaApp.Services
{
    // Bloqueia temporariamente um e-mail após várias senhas erradas.
    // Fica em memória (singleton): reiniciar o servidor zera os contadores.
    public class LoginAttemptService
    {
        private const int MaxTentativas = 5;
        private static readonly TimeSpan Janela = TimeSpan.FromMinutes(15);
        private static readonly TimeSpan Bloqueio = TimeSpan.FromMinutes(15);

        private class Registro
        {
            public int Falhas;
            public DateTime PrimeiraFalha;
            public DateTime? BloqueadoAte;
        }

        private readonly ConcurrentDictionary<string, Registro> _registros = new();

        private static string Chave(string? email) =>
            (email ?? string.Empty).Trim().ToLowerInvariant();

        public bool EstaBloqueado(string? email, out int minutosRestantes)
        {
            minutosRestantes = 0;

            if (!_registros.TryGetValue(Chave(email), out var r))
                return false;

            lock (r)
            {
                if (r.BloqueadoAte.HasValue && r.BloqueadoAte.Value > DateTime.UtcNow)
                {
                    minutosRestantes =
                        (int)Math.Ceiling((r.BloqueadoAte.Value - DateTime.UtcNow).TotalMinutes);
                    return true;
                }
            }

            return false;
        }

        public void RegistrarFalha(string? email)
        {
            var agora = DateTime.UtcNow;
            var r = _registros.GetOrAdd(Chave(email), _ => new Registro { PrimeiraFalha = agora });

            lock (r)
            {
                if (agora - r.PrimeiraFalha > Janela || (r.BloqueadoAte.HasValue && r.BloqueadoAte <= agora))
                {
                    r.Falhas = 0;
                    r.PrimeiraFalha = agora;
                    r.BloqueadoAte = null;
                }

                r.Falhas++;

                if (r.Falhas >= MaxTentativas)
                    r.BloqueadoAte = agora + Bloqueio;
            }

            // Limpeza simples para a memória não crescer sem limite
            if (_registros.Count > 10000)
            {
                foreach (var par in _registros)
                {
                    if (agora - par.Value.PrimeiraFalha > Janela)
                        _registros.TryRemove(par.Key, out _);
                }
            }
        }

        public void Limpar(string? email) => _registros.TryRemove(Chave(email), out _);
    }
}
