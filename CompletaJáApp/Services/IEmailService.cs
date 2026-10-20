using System.Threading.Tasks;

namespace CompletaJaApp.Services
{
    public interface IEmailService
    {
        Task EnviarAsync(string destinatario, string assunto, string corpoHtml);
    }
}
