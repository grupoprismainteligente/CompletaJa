import 'package:flutter/material.dart';

/// Mensagem rápida na parte de baixo da tela (SnackBar).
void mostrarAviso(BuildContext context, String mensagem) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(mensagem)));
}
