/* * Arquivo: album-add.js
 * Tela: Adicionar Álbum (/Album/Add)
 * Função: Gerencia o preenchimento automático de sugestões, preview da foto da capa e validação de formulário.
 */

// Garante que o JavaScript só execute após todo o HTML da tela ser carregado
document.addEventListener('DOMContentLoaded', function () {

    // --- 1. PREVIEW DA IMAGEM DE CAPA ---
    const inputCapa = document.getElementById('inputCapa');
    if (inputCapa) {
        inputCapa.addEventListener('change', function (e) {
            const arquivo = e.target.files[0];
            if (arquivo) {
                // Cria uma URL temporária para a imagem escolhida e joga no <img> para o usuário ver
                const url = URL.createObjectURL(arquivo);
                const preview = document.getElementById('previewCapa');
                preview.src = url;
                preview.style.display = 'block';

                // Oculta o ícone de câmera e o texto "Adicionar Capa"
                document.getElementById('uploadContent').style.display = 'none';
            }
        });
    }

    // --- 2. VALIDAÇÃO DO FORMULÁRIO E VERIFICAÇÃO DE DUPLICIDADE ---
    const formCriarAlbum = document.getElementById('formCriarAlbum');
    if (formCriarAlbum) {
        formCriarAlbum.addEventListener('submit', async function (e) {
            // Trava o envio padrão do formulário para podermos validar primeiro
            e.preventDefault();

            const nome = document.getElementById('inputNome').value;
            const qtd = document.getElementById('inputQtd').value;
            const categoria = document.getElementById('selectCategoria').value;
            const capaEnviada = document.getElementById('inputCapa').files.length > 0;

            // Validação de campos vazios
            if (!nome || !qtd || !categoria || !capaEnviada) {
                alert("O cadastro não pode ser efetuado. Por favor, preencha todos os campos e adicione a capa do álbum.");
                return;
            }

            // Consulta o back-end (C#) para verificar se já existe um álbum igual
            const url = `/Album/VerificarDuplicidade?nome=${encodeURIComponent(nome)}&quantidade=${qtd}`;
            const response = await fetch(url, { method: 'POST' });
            const data = await response.json();

            // Se for duplicado, pede confirmação ao usuário
            if (data.duplicado) {
                const prosseguir = confirm(`Atenção: Um álbum semelhante chamado "${data.nomeSemelhante}" com exatas ${qtd} figurinhas já existe no sistema. Deseja confirmar o cadastro do seu novo álbum mesmo assim?`);

                if (!prosseguir) {
                    return; // Cancela o envio
                }
            }

            // Se tudo estiver certo, dispara o formulário
            this.submit();
        });
    }
});

// --- 3. FUNÇÃO DE PREENCHIMENTO AUTOMÁTICO (SUGESTÕES) ---
// Fica fora do DOMContentLoaded pois é chamada diretamente pelo clique (onclick) no HTML
function preencher(nome, categoria, qtd) {
    const campoNome = document.getElementById('inputNome');
    const campoCategoria = document.getElementById('selectCategoria');
    const campoQtd = document.getElementById('inputQtd');

    // Preenche os valores nos inputs
    campoNome.value = nome;
    campoCategoria.value = (categoria !== '') ? categoria : "";
    campoQtd.value = qtd;

    // Efeito visual (pisca os campos em azul) para mostrar ao usuário que foram preenchidos
    [campoNome, campoCategoria, campoQtd].forEach(el => {
        el.style.transition = "background-color 0.3s";
        el.style.backgroundColor = "#eef2ff";
        el.style.borderColor = "#1D58E6";

        setTimeout(() => {
            el.style.backgroundColor = "#fff";
            el.style.borderColor = "#E5E7EB";
        }, 600);
    });
}