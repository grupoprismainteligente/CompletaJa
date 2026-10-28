import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Caixa de busca com lupa (a `.search-container` do site).
class CampoBusca extends StatelessWidget {
  const CampoBusca({super.key, required this.dica, required this.aoMudar});

  final String dica;

  /// Chamado a cada letra digitada, com o texto atual.
  final ValueChanged<String> aoMudar;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: aoMudar,
      style: AppTextos.campoBusca,
      decoration: InputDecoration(
        hintText: dica,
        hintStyle: AppTextos.dicaBusca,
        prefixIcon: const Icon(Icons.search, color: AppCores.textoDesabilitado),
        contentPadding: const EdgeInsets.symmetric(vertical: AppEspacos.compacto),
        enabledBorder: _borda(AppCores.bordaCampo),
        focusedBorder: _borda(AppCores.primaria),
      ),
    );
  }

  OutlineInputBorder _borda(Color cor) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRaios.medio),
        borderSide: BorderSide(color: cor),
      );
}
