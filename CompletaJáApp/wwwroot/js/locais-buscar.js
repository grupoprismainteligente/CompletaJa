/* * Arquivo: locais-buscar.js
 * Tela: Buscar Locais (/Locais/Buscar)
 * Função: Filtro de busca insensível a maiúsculas (Nome, Endereço, CNPJ) e Popup de confirmação de vínculo.
 */

// --- 1. FILTRO GLOBAL MULTICAMPOS (Case-Insensitive) ---
function filtrarGlobal() {
    // Captura o valor digitado e limpa espaços extras
    const termo = document.getElementById('inputBuscaGlobal').value.toLowerCase().trim();

    // Limpa caracteres especiais do termo digitado para comparar CNPJ numérico puro
    const termoCnpjPuro = termo.replace(/[\.\-\/]/g, "");

    // Seleciona os cartões de locais reais (ignora o cartão de "Criar Novo")
    const cards = document.querySelectorAll('.local-card');

    cards.forEach(card => {
        // Coleta os atributos mapeados em letras minúsculas
        const nome = card.getAttribute('data-nome') || "";
        const endereco = card.getAttribute('data-endereco') || "";
        const cnpj = card.getAttribute('data-cnpj') || "";

        // Testa se o termo se encaixa em qualquer um dos três critérios
        if (nome.includes(termo) || endereco.includes(termo) || cnpj.includes(termoCnpjPuro)) {
            card.style.display = ''; // Exibe
        } else {
            card.style.display = 'none'; // Oculta
        }
    });
}

// --- 2. POPUP DE CONFIRMAÇÃO PARA SE VINCULAR ---
function confirmarVinculo(id, nomeLocal) {
    // Dispara a janela nativa de confirmação do navegador (Sim/Cancelar)
    const prosseguir = confirm(`Deseja se vincular ao estabelecimento "${nomeLocal}"?\n\nAo confirmar, este local aparecerá na sua Home e suas figurinhas entrarão no radar de trocas dessa área.`);

    if (prosseguir) {
        // Atribui o ID do local selecionado ao campo do formulário oculto
        document.getElementById('inputLocalId').value = id;
        // Envia os dados com segurança via método POST para o Controller
        document.getElementById('formVincular').submit();
    }
}