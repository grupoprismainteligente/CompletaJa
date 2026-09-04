/* * Arquivo: locais-detalhes.js
 * Tela: Detalhes do Local (/Locais/Detalhes)
 * Função: Exibe uma caixa de confirmação (popup) antes de desvincular o usuário do local.
 */

document.addEventListener('DOMContentLoaded', function () {
    const formDesvincular = document.getElementById('formDesvincular');

    if (formDesvincular) {
        formDesvincular.addEventListener('submit', function (e) {
            // Interrompe o envio automático para pedir a confirmação do usuário
            e.preventDefault();

            const nomeLocal = document.getElementById('nomeLocalTitulo').innerText;

            // Exibe o popup nativo de confirmação
            const prosseguir = confirm(`Tem certeza que deseja se desvincular de "${nomeLocal}"?\n\nAo confirmar, você deixará de ver matches automáticos de troca com os colecionadores cadastrados neste ponto.`);

            if (prosseguir) {
                // Se o usuário clicou em OK, libera o envio do formulário (POST)
                this.submit();
            }
        });
    }
});