/// Uma figurinha da grade 1..N de um álbum.
/// `quantidade`: 0 = falta, 1 = colada, >1 = repetida (repetidas = quantidade - 1).
class Figurinha {
  const Figurinha({required this.codigo, required this.nome, required this.quantidade});

  /// Número com no mínimo 2 dígitos: "01", "02", ..., "99", "100".
  final String codigo;
  final String nome;
  final int quantidade;

  bool get faltante => quantidade == 0;
  bool get repetida => quantidade > 1;
  int get extras => quantidade > 1 ? quantidade - 1 : 0;

  factory Figurinha.fromJson(Map<String, dynamic> json) => Figurinha(
        codigo: json['codigo'] as String,
        nome: json['nome'] as String? ?? '',
        quantidade: json['quantidade'] as int? ?? 0,
      );
}
