/// O usuário logado. Espelha o `UsuarioDto` da API (`{ id, nome, fotoUrl }`).
class Usuario {
  const Usuario({required this.id, required this.nome, required this.fotoUrl});

  final int id;
  final String nome;

  /// Pode ser URL completa (Cloudinary) ou relativa (`/images/default-avatar.png`).
  /// Use `Config.urlImagem` para montar o endereço final.
  final String? fotoUrl;

  /// `fromJson` transforma o Map que veio do JSON da API num objeto Dart.
  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
        id: json['id'] as int,
        nome: json['nome'] as String? ?? '',
        fotoUrl: json['fotoUrl'] as String?,
      );

  /// O inverso: usado para guardar o usuário no armazenamento seguro.
  Map<String, dynamic> toJson() => {'id': id, 'nome': nome, 'fotoUrl': fotoUrl};
}
