/* * Arquivo: locais-index.js
 * Tela: Listagem de Locais (/Locais/Index)
 * Função: Filtra os locais na tela em tempo real conforme o usuário digita.
 */

function filtrarLocais() {
    // 1. Captura o texto da busca e converte para minúsculas
    const termo = document.getElementById('inputBuscaLocal').value.toLowerCase();

    // 2. Pega todos os cartões de locais renderizados
    const cards = document.querySelectorAll('.local-card');

    // 3. Percorre cada cartão verificando o nome do local
    cards.forEach(card => {
        const nomeLocal = card.querySelector('h3').innerText.toLowerCase();

        // Exibe se incluir o termo da busca, oculta caso contrário
        if (nomeLocal.includes(termo)) {
            card.style.display = '';
        } else {
            card.style.display = 'none';
        }
    });
}