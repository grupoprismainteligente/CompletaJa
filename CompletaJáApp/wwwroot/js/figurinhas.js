/* ==========================================================================
   SISTEMA COMPLETAJÁ - MÓDULO DE FIGURINHAS (JS)
   Gerenciamento dinâmico de estados, visor de quantidade, modal e busca.
   ========================================================================== */

// Armazena temporariamente a quantidade alterada dentro do modal ativo
let qtdAtual = 0;

/**
 * Evento executado assim que a página é carregada por completo.
 */
document.addEventListener("DOMContentLoaded", function () {

    // 1. Corrige o gatilho "onchange" do dropdown de filtros injetado via View.
    const selectFiltro = document.getElementById('selectFiltro');
    if (selectFiltro) {
        selectFiltro.setAttribute('onchange', 'filtrar()');
    }

    // ========================================================================
    // MÁGICA DE UX: MANTER A POSIÇÃO DA ROLAGEM (SCROLL)
    // ========================================================================

    // A) RECUPERA: Assim que a página carrega, verifica se existe uma rolagem salva
    const scrollSalvo = sessionStorage.getItem('posicaoRolagemFigurinhas');
    if (scrollSalvo) {
        // Pula a tela imediatamente para a posição salva
        window.scrollTo(0, parseInt(scrollSalvo));
        // Limpa a memória para não interferir nas próximas vezes que entrar na tela
        sessionStorage.removeItem('posicaoRolagemFigurinhas');
    }

    // B) SALVA: Intercepta o botão de salvar do modal milissegundos antes do envio
    const formModal = document.querySelector('#modalSticker form');
    if (formModal) {
        formModal.addEventListener('submit', function () {
            // Anota a posição Y (vertical) exata em que o usuário está navegando
            sessionStorage.setItem('posicaoRolagemFigurinhas', window.scrollY);
        });
    }
});

/**
 * Abre o modal de edição e preenche os campos com os dados da figurinha selecionada.
 * @param {string} codigo - O número de identificação da figurinha (Ex: "01", "02").
 * @param {string} nome - O nome customizado do jogador ou item (se houver).
 * @param {number} qtd - A quantidade atual em mãos do usuário.
 */
function abrirModal(codigo, nome, qtd) {
    document.getElementById('modalSticker').style.display = 'flex';
    document.getElementById('modalNum').innerText = codigo;
    document.getElementById('inputCodigoModal').value = codigo;
    document.getElementById('inputNomeModal').value = nome;

    qtdAtual = qtd;
    atualizarVisorQtd();

    // A MARRETA DO JAVASCRIPT: Força o VLibras a sumir instantaneamente
    const widgetVLibras = document.querySelector('[vw]');
    if (widgetVLibras) {
        widgetVLibras.style.setProperty('display', 'none', 'important');
    }
}

/**
 * Oculta o modal de edição da tela.
 */
function fecharModal() {
    document.getElementById('modalSticker').style.display = 'none';

    // O modal fechou, devolvemos o VLibras para a tela
    const widgetVLibras = document.querySelector('[vw]');
    if (widgetVLibras) {
        widgetVLibras.style.setProperty('display', 'block', 'important');
    }
}

/**
 * Incrementa ou decrementa o visor de quantidade no modal, impedindo valores negativos.
 * @param {number} valor - Use 1 para somar ou -1 para subtrair.
 */
function mudarQtd(valor) {
    qtdAtual += valor;
    if (qtdAtual < 0) qtdAtual = 0; // Trava de segurança: impede coleções negativas
    atualizarVisorQtd();
}

/**
 * Atualiza o texto visual do contador e injeta o valor real no campo oculto (hidden) do Form.
 */
function atualizarVisorQtd() {
    document.getElementById('displayQtd').innerText = qtdAtual;
    document.getElementById('inputQtdReal').value = qtdAtual;
}

/**
 * Fecha o modal automaticamente se o usuário clicar na área escura (background) fora do card.
 */
window.onclick = function (event) {
    let modal = document.getElementById('modalSticker');
    if (event.target == modal) {
        fecharModal(); // Como o fecharModal já tem o comando para voltar o VLibras, ele voltará ao normal aqui também!
    }
}

/**
 * Realiza o filtro dinâmico em tempo real na listagem combinando a busca por texto e dropdown.
 */
function filtrar() {
    const termo = document.getElementById('inputBusca').value.toLowerCase().trim();
    const filtro = document.getElementById('selectFiltro').value;
    const cards = document.querySelectorAll('.fig-card');

    cards.forEach(card => {
        const num = card.getAttribute('data-num').toLowerCase();
        const qty = parseInt(card.getAttribute('data-qty'));
        let mostrar = true;

        // Regra 1: Filtro por barra de pesquisa (número da figurinha)
        if (termo && !num.includes(termo)) {
            mostrar = false;
        }

        // Regra 2: Filtro por Dropdown de Categoria (Faltantes)
        if (filtro === 'faltantes' && qty > 0) {
            mostrar = false;
        }

        // Regra 3: Filtro por Dropdown de Categoria (Repetidas)
        if (filtro === 'repetidas' && qty < 2) {
            mostrar = false;
        }

        // Aplica o estado de exibição final no elemento HTML
        card.style.display = mostrar ? 'flex' : 'none';
    });
}