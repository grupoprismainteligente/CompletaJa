/* ==========================================================================
   SISTEMA COMPLETAJÁ - MÓDULO DE PERFIL DE USUÁRIO (JS)
   Gerenciamento de gatilhos de clique e preview de upload em tempo real.
   ========================================================================== */

/**
 * Dispara o clique no input de arquivo oculto quando o usuário clica na foto redonda.
 */
function dispararUpload() {
    document.getElementById('inputFotoReal').click();
}

/**
 * Lê o arquivo de imagem selecionado pelo usuário e atualiza a tag <img> em tempo real.
 * @param {Event} event - Evento de alteração do input file.
 */
function previewImagem(event) {
    const input = event.target;

    // Verifica se existe um arquivo selecionado
    if (input.files && input.files[0]) {
        const reader = new FileReader();

        // Define a ação a ser tomada quando o arquivo terminar de ser lido
        reader.onload = function (e) {
            const imgPreview = document.getElementById('imgPreview');
            if (imgPreview) {
                imgPreview.src = e.target.result; // Altera o source para o arquivo local temporário
            }
        };

        // Lê a imagem física como uma URL base64
        reader.readAsDataURL(input.files[0]);
    }
}