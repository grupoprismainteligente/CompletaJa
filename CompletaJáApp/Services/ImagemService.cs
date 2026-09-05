using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using System;
using System.Collections.Generic;
using System.IO;
using System.Threading.Tasks;

namespace CompletaJaApp.Services
{
    public class ImagemService
    {
        private const long TamanhoMaximo = 5 * 1024 * 1024;

        private readonly IWebHostEnvironment _environment;

        private static readonly HashSet<string> ExtensoesPermitidas =
            new HashSet<string>(StringComparer.OrdinalIgnoreCase)
            {
                ".jpg",
                ".jpeg",
                ".png",
                ".webp"
            };

        private static readonly HashSet<string> PastasPermitidas =
            new HashSet<string>(StringComparer.OrdinalIgnoreCase)
            {
                "usuarios",
                "perfis",
                "albuns",
                "locais"
            };

        public ImagemService(IWebHostEnvironment environment)
        {
            _environment = environment;
        }

        public async Task<string> SalvarAsync(
            IFormFile arquivo,
            string subpasta)
        {
            if (arquivo == null || arquivo.Length == 0)
            {
                throw new InvalidOperationException(
                    "Selecione uma imagem válida.");
            }

            if (arquivo.Length > TamanhoMaximo)
            {
                throw new InvalidOperationException(
                    "A imagem deve possuir no máximo 5 MB.");
            }

            if (!PastasPermitidas.Contains(subpasta))
            {
                throw new InvalidOperationException(
                    "A pasta de destino não é permitida.");
            }

            string extensaoInformada =
                Path.GetExtension(arquivo.FileName).ToLowerInvariant();

            if (!ExtensoesPermitidas.Contains(extensaoInformada))
            {
                throw new InvalidOperationException(
                    "Formato não permitido. Utilize JPG, JPEG, PNG ou WebP.");
            }

            string? extensaoReal =
                await DetectarExtensaoRealAsync(arquivo);

            if (extensaoReal == null)
            {
                throw new InvalidOperationException(
                    "O arquivo enviado não é uma imagem válida.");
            }

            string extensaoNormalizada =
                extensaoInformada == ".jpeg"
                    ? ".jpg"
                    : extensaoInformada;

            if (extensaoNormalizada != extensaoReal)
            {
                throw new InvalidOperationException(
                    "O conteúdo do arquivo não corresponde à sua extensão.");
            }

            string webRootPath = _environment.WebRootPath
                ?? throw new InvalidOperationException(
                    "A pasta pública do sistema não foi encontrada.");

            string pastaFisica = Path.Combine(
                webRootPath,
                "uploads",
                subpasta);

            Directory.CreateDirectory(pastaFisica);

            string nomeArquivo =
                Guid.NewGuid().ToString("N") + extensaoReal;

            string caminhoCompleto =
                Path.Combine(pastaFisica, nomeArquivo);

            await using var stream = new FileStream(
                caminhoCompleto,
                FileMode.CreateNew,
                FileAccess.Write,
                FileShare.None);

            await arquivo.CopyToAsync(stream);

            return $"/uploads/{subpasta}/{nomeArquivo}";
        }

        private static async Task<string?> DetectarExtensaoRealAsync(
            IFormFile arquivo)
        {
            byte[] cabecalho = new byte[12];

            await using var stream = arquivo.OpenReadStream();

            int bytesLidos = await stream.ReadAsync(
                cabecalho.AsMemory(0, cabecalho.Length));

            // JPEG
            if (bytesLidos >= 3 &&
                cabecalho[0] == 0xFF &&
                cabecalho[1] == 0xD8 &&
                cabecalho[2] == 0xFF)
            {
                return ".jpg";
            }

            // PNG
            if (bytesLidos >= 8 &&
                cabecalho[0] == 0x89 &&
                cabecalho[1] == 0x50 &&
                cabecalho[2] == 0x4E &&
                cabecalho[3] == 0x47 &&
                cabecalho[4] == 0x0D &&
                cabecalho[5] == 0x0A &&
                cabecalho[6] == 0x1A &&
                cabecalho[7] == 0x0A)
            {
                return ".png";
            }

            // WebP
            if (bytesLidos >= 12 &&
                cabecalho[0] == (byte)'R' &&
                cabecalho[1] == (byte)'I' &&
                cabecalho[2] == (byte)'F' &&
                cabecalho[3] == (byte)'F' &&
                cabecalho[8] == (byte)'W' &&
                cabecalho[9] == (byte)'E' &&
                cabecalho[10] == (byte)'B' &&
                cabecalho[11] == (byte)'P')
            {
                return ".webp";
            }

            return null;
        }
    }
}