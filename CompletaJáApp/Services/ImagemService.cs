using CloudinaryDotNet;
using CloudinaryDotNet.Actions;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Configuration;
using System;
using System.Collections.Generic;
using System.IO;
using System.Threading.Tasks;

namespace CompletaJaApp.Services
{
    public class ImagemService
    {
        private const long TamanhoMaximo =
            5 * 1024 * 1024;

        private readonly Cloudinary _cloudinary;

        private static readonly HashSet<string>
            ExtensoesPermitidas =
                new HashSet<string>(
                    StringComparer.OrdinalIgnoreCase)
                {
                    ".jpg",
                    ".jpeg",
                    ".png",
                    ".webp"
                };

        private static readonly HashSet<string>
            PastasPermitidas =
                new HashSet<string>(
                    StringComparer.OrdinalIgnoreCase)
                {
                    "usuarios",
                    "perfis",
                    "albuns",
                    "locais"
                };

        public ImagemService(
            IConfiguration configuration)
        {
            string? cloudName =
                configuration["Cloudinary:CloudName"];

            string? apiKey =
                configuration["Cloudinary:ApiKey"];

            string? apiSecret =
                configuration["Cloudinary:ApiSecret"];

            if (string.IsNullOrWhiteSpace(cloudName) ||
                string.IsNullOrWhiteSpace(apiKey) ||
                string.IsNullOrWhiteSpace(apiSecret))
            {
                throw new InvalidOperationException(
                    "As credenciais do Cloudinary não foram configuradas.");
            }

            var conta = new Account(
                cloudName,
                apiKey,
                apiSecret);

            _cloudinary =
                new Cloudinary(conta);

            _cloudinary.Api.Secure = true;
        }

        public async Task<string> SalvarAsync(
            IFormFile arquivo,
            string subpasta)
        {
            if (arquivo == null ||
                arquivo.Length == 0)
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
                Path.GetExtension(
                    arquivo.FileName)
                    .ToLowerInvariant();

            if (!ExtensoesPermitidas.Contains(
                    extensaoInformada))
            {
                throw new InvalidOperationException(
                    "Formato não permitido. Utilize JPG, JPEG, PNG ou WebP.");
            }

            string? extensaoReal =
                await DetectarExtensaoRealAsync(
                    arquivo);

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

            string nomeArquivo =
                Guid.NewGuid().ToString("N");

            await using var stream =
                arquivo.OpenReadStream();

            var parametros =
                new ImageUploadParams
                {
                    File = new FileDescription(
                        nomeArquivo + extensaoReal,
                        stream),

                    PublicId = nomeArquivo,

                    Folder =
                        $"completaja/{subpasta}",

                    Overwrite = false,

                    UseFilename = false,

                    UniqueFilename = false
                };

            ImageUploadResult resultado;

            try
            {
                resultado =
                    await _cloudinary.UploadAsync(
                        parametros);
            }
            catch (Exception)
            {
                throw new InvalidOperationException(
                    "Não foi possível enviar a imagem. Tente novamente.");
            }

            if (resultado.Error != null ||
                resultado.SecureUrl == null)
            {
                throw new InvalidOperationException(
                    "Não foi possível armazenar a imagem no Cloudinary.");
            }

            return resultado
                .SecureUrl
                .ToString();
        }

        private static async Task<string?>
            DetectarExtensaoRealAsync(
                IFormFile arquivo)
        {
            byte[] cabecalho =
                new byte[12];

            await using var stream =
                arquivo.OpenReadStream();

            int bytesLidos =
                await stream.ReadAsync(
                    cabecalho.AsMemory(
                        0,
                        cabecalho.Length));

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