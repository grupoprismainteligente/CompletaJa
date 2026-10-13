import 'package:flutter/material.dart';

import '../widgets/mensagem_central.dart';

/// Meus Álbuns. PROVISÓRIA: a lista real (vinda da API) entra na etapa 4.
class MeusAlbunsScreen extends StatelessWidget {
  const MeusAlbunsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meus Álbuns')),
      body: const MensagemCentral(
        icone: Icons.collections_bookmark_outlined,
        titulo: 'Seus álbuns',
        texto: 'Os álbuns que você coleciona vão aparecer aqui.',
      ),
    );
  }
}
