/* * Arquivo: album-index.js
 * Tela: Listagem de Álbuns (/Album/Index)
 * Função: Controla a busca em tempo real dos cartões de álbuns na tela.
 */

function filtrarAlbuns() {
    // 1. Captura o texto digitado pelo usuário e converte para minúsculas
    const termoBusca = document.getElementById('inputBuscaAlbum').value.toLowerCase();

    // 2. Seleciona todos os cartões de álbuns renderizados na tela
    const cartoes = document.querySelectorAll('.album-card');

    // 3. Percorre cada cartão para verificar se o nome bate com a busca
    cartoes.forEach(cartao => {
        // Encontra a tag <h3> dentro do cartão, que é onde está o nome do álbum
        const nomeAlbum = cartao.querySelector('h3').innerText.toLowerCase();

        // Se o nome contém o termo digitado, remove o estilo 'none' (exibe). Se não, oculta (none).
        if (nomeAlbum.includes(termoBusca)) {
            cartao.style.display = '';
        } else {
            cartao.style.display = 'none';
        }
    });
}