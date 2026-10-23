using System;
using System.Net;
using System.Net.Mail;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace CompletaJaApp.Services
{
    // Envia e-mail por SMTP. Configuração (variáveis de ambiente ou user-secrets):
    //   Smtp__Host, Smtp__Port (587), Smtp__User, Smtp__Password, Smtp__From
    // Sem Smtp__Host configurado, o e-mail é apenas escrito no log
    // (útil para testar localmente: copie o link do console).
    public class SmtpEmailService : IEmailService
    {
        private readonly IConfiguration _config;
        private readonly ILogger<SmtpEmailService> _logger;

        public SmtpEmailService(IConfiguration config, ILogger<SmtpEmailService> logger)
        {
            _config = config;
            _logger = logger;
        }

        public async Task EnviarAsync(string destinatario, string assunto, string corpoHtml)
        {
            var host = _config["Smtp:Host"];

            if (string.IsNullOrWhiteSpace(host))
            {
                _logger.LogWarning(
                    "SMTP não configurado. E-mail para {Destino} | {Assunto} | {Corpo}",
                    destinatario, assunto, corpoHtml);
                return;
            }

            var porta = int.TryParse(_config["Smtp:Port"], out var p) ? p : 587;
            var usuario = _config["Smtp:User"];
            var senha = _config["Smtp:Password"];
            var remetente = _config["Smtp:From"] ?? usuario ?? "nao-responder@completaja.com";

            using var mensagem = new MailMessage(remetente, destinatario, assunto, corpoHtml)
            {
                IsBodyHtml = true
            };

            using var cliente = new SmtpClient(host, porta)
            {
                EnableSsl = true,
                Credentials = string.IsNullOrEmpty(usuario)
                    ? CredentialCache.DefaultNetworkCredentials
                    : new NetworkCredential(usuario, senha)
            };

            await cliente.SendMailAsync(mensagem);
        }
    }
}
