using System.Linq;

namespace CompletaJaApp.Services
{
    public static class CpfHelper
    {
        // Validação com os dígitos verificadores (mesma regra do JavaScript da tela)
        public static bool Validar(string? cpf)
        {
            var d = new string((cpf ?? string.Empty).Where(char.IsDigit).ToArray());

            if (d.Length != 11 || d.Distinct().Count() == 1)
                return false;

            for (int t = 9; t < 11; t++)
            {
                int soma = 0;
                for (int i = 0; i < t; i++)
                    soma += (d[i] - '0') * (t + 1 - i);

                int dv = (soma * 10) % 11;
                if (dv == 10) dv = 0;

                if (dv != d[t] - '0')
                    return false;
            }

            return true;
        }

        // 12345678901 -> ***.456.789-**  (14 caracteres, cabe em MaxLength(14))
        public static string Mascarar(string? cpf)
        {
            var d = new string((cpf ?? string.Empty).Where(char.IsDigit).ToArray());

            if (d.Length != 11)
                return "***.***.***-**";

            return $"***.{d.Substring(3, 3)}.{d.Substring(6, 3)}-**";
        }
    }
}
