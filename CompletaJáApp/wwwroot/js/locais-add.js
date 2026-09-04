/* * Arquivo: locais-add.js
 * Tela: Cadastrar Novo Local (/Locais/Add)
 * Função: Controla o preview da imagem e impede submissões com CNPJ idêntico via API assíncrona.
 */

document.addEventListener('DOMContentLoaded', function () {

    // --- 1. EXIBIÇÃO EM TEMPO REAL DA FOTO SELECIONADA ---
    const inputFoto = document.getElementById('inputFoto');
    if (inputFoto) {
        inputFoto.addEventListener('change', function (e) {
            const arquivo = e.target.files[0];
            if (arquivo) {
                const url = URL.createObjectURL(arquivo);
                const preview = document.getElementById('previewFoto');
                preview.src = url;
                preview.style.display = 'block';
                document.getElementById('uploadContent').style.display = 'none';
            }
        });
    }

    // --- 2. VALIDAÇÕES ANTIDUPLICIDADE ANTES DO ENVIO ---
    const formLocal = document.getElementById('formCriarLocal');
    if (formLocal) {
        formLocal.addEventListener('submit', async function (e) {
            e.preventDefault(); // Trava a requisição padrão

            const nome = document.getElementById('inputNomeLocal').value;
            const cnpj = document.getElementById('inputCNPJ').value;
            const endereco = document.getElementById('inputEndereco').value;
            const area = document.getElementById('inputArea').value;
            const fotoPronta = document.getElementById('inputFoto').files.length > 0;

            if (!nome || !cnpj || !endereco || !area || !fotoPronta) {
                alert("Operação negada: certifique-se de preencher todos os campos obrigatórios e carregar uma imagem.");
                return;
            }

            // Consulta o back-end para bloquear cadastros com o mesmo CNPJ
            try {
                const url = `/Locais/VerificarDuplicidade?cnpj=${encodeURIComponent(cnpj)}`;
                const response = await fetch(url, { method: 'POST' });

                if (response.ok) {
                    const data = await response.json();
                    if (data.duplicado) {
                        alert(`Bloqueio de Cadastro: O CNPJ inserido já está associado ao ponto "${data.nomeLocal}" no sistema.\n\nPor favor, utilize a barra de pesquisas para localizar e vincular-se a ele.`);
                        return;
                    }
                }
            } catch (erro) {
                console.warn("Validação offline. Prosseguindo...");
            }

            // Libera o envio se todas as travas passaram
            this.submit();
        });
    }
});