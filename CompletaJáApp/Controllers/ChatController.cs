using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Http;
using CompletaJaApp.Data;
using CompletaJaApp.Models;
using System.Linq;
using System;

namespace CompletaJáApp.Controllers
{
    public class ChatController : Controller
    {
        private readonly CompletaJaContext _context;

        public ChatController(CompletaJaContext context)
        {
            _context = context;
        }

        // Carrega a tela com o histórico de mensagens
        [HttpGet]
        public IActionResult Conversar(int usuarioId)
        {
            ViewBag.FotoUsuario = HttpContext.Session.GetString("FotoUsuario") ?? "/images/default-avatar.png";
            int meuId = HttpContext.Session.GetInt32("UsuarioId")!.Value;

            var outroUsuario = _context.Usuarios.Find(usuarioId);
            if (outroUsuario == null) return NotFound();

            // Busca as mensagens que foram de mim pra ele, ou dele pra mim, em ordem de data
            var mensagens = _context.Mensagens
                .Where(m => (m.RemetenteId == meuId && m.DestinatarioId == usuarioId) ||
                            (m.RemetenteId == usuarioId && m.DestinatarioId == meuId))
                .OrderBy(m => m.DataEnvio)
                .ToList();

            ViewBag.MeuId = meuId;
            ViewBag.OutroUsuario = outroUsuario;

            return View(mensagens);
        }

        // Salva uma nova mensagem enviada
        [HttpPost]
        public IActionResult Enviar(int DestinatarioId, string Texto)
        {
            int meuId =
                HttpContext.Session.GetInt32("UsuarioId")!.Value;

            if (DestinatarioId <= 0 ||
                DestinatarioId == meuId ||
                string.IsNullOrWhiteSpace(Texto))
            {
                return BadRequest();
            }

            string textoLimpo = Texto.Trim();

            if (textoLimpo.Length > 1000)
            {
                return BadRequest();
            }

            bool destinatarioExiste =
                _context.Usuarios.Any(u => u.Id == DestinatarioId);

            if (!destinatarioExiste)
            {
                return NotFound();
            }

            var novaMensagem = new Mensagem
            {
                RemetenteId = meuId,
                DestinatarioId = DestinatarioId,
                Texto = textoLimpo,
                DataEnvio = DateTime.Now
            };

            _context.Mensagens.Add(novaMensagem);
            _context.SaveChanges();

            return RedirectToAction(
                "Conversar",
                new { usuarioId = DestinatarioId });
        }
    }
}