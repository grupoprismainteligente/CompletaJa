using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.SignalR;
using System.Threading.Tasks;

namespace CompletaJaApp.Hubs
{
    public class ChatHub : Hub
    {
        public override async Task OnConnectedAsync()
        {
            int? usuarioId =
                Context.GetHttpContext()?.Session.GetInt32("UsuarioId");

            if (!usuarioId.HasValue)
            {
                Context.Abort();
                return;
            }

            Context.Items["UsuarioId"] = usuarioId.Value;

            await Groups.AddToGroupAsync(
                Context.ConnectionId,
                ObterGrupoUsuario(usuarioId.Value));

            await base.OnConnectedAsync();
        }

        public async Task EnviarMensagem(
            int usuarioIdDestino,
            string mensagem)
        {
            if (!Context.Items.TryGetValue(
                    "UsuarioId",
                    out object? usuarioSalvo) ||
                usuarioSalvo is not int remetenteId)
            {
                throw new HubException("Sessão de usuário inválida.");
            }

            if (usuarioIdDestino <= 0 ||
                usuarioIdDestino == remetenteId)
            {
                throw new HubException("Destinatário inválido.");
            }

            if (string.IsNullOrWhiteSpace(mensagem))
            {
                return;
            }

            string mensagemLimpa = mensagem.Trim();

            if (mensagemLimpa.Length > 1000)
            {
                throw new HubException(
                    "A mensagem deve possuir no máximo 1000 caracteres.");
            }

            Task enviarAoRemetente = Clients
                .Group(ObterGrupoUsuario(remetenteId))
                .SendAsync(
                    "ReceberMensagem",
                    remetenteId,
                    usuarioIdDestino,
                    mensagemLimpa);

            Task enviarAoDestinatario = Clients
                .Group(ObterGrupoUsuario(usuarioIdDestino))
                .SendAsync(
                    "ReceberMensagem",
                    remetenteId,
                    usuarioIdDestino,
                    mensagemLimpa);

            await Task.WhenAll(
                enviarAoRemetente,
                enviarAoDestinatario);
        }

        private static string ObterGrupoUsuario(int usuarioId)
        {
            return $"usuario-{usuarioId}";
        }
    }
}