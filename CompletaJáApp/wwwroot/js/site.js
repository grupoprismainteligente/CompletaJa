(function () {
    "use strict";

    const tamanhoMaximoImagem =
        5 * 1024 * 1024;

    const mensagemTamanho =
        "A imagem deve possuir no máximo 5 MB.";

    document.addEventListener(
        "change",
        function (event) {
            const input = event.target;

            if (!(input instanceof HTMLInputElement) ||
                input.type !== "file") {
                return;
            }

            input.dataset.imagemInvalida =
                "false";

            if (!input.files ||
                input.files.length === 0) {
                return;
            }

            const possuiImagemMuitoGrande =
                Array.from(input.files).some(
                    arquivo =>
                        arquivo.size >
                        tamanhoMaximoImagem);

            if (!possuiImagemMuitoGrande) {
                return;
            }

            input.dataset.imagemInvalida =
                "true";

            input.value = "";

            alert(mensagemTamanho);
        },
        true);

    document.addEventListener(
        "submit",
        function (event) {
            const formulario = event.target;

            if (!(formulario instanceof
                HTMLFormElement)) {
                return;
            }

            const imagemInvalida =
                formulario.querySelector(
                    'input[type="file"][data-imagem-invalida="true"]');

            if (!imagemInvalida) {
                return;
            }

            event.preventDefault();
            event.stopImmediatePropagation();

            alert(mensagemTamanho);
        },
        true);
})();