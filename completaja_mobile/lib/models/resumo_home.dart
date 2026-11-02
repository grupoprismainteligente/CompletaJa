/// Contadores da Home. Espelha o `HomeDto` da API.
class ResumoHome {
  const ResumoHome({required this.repetidas, required this.faltantes});

  final int repetidas;
  final int faltantes;

  factory ResumoHome.fromJson(Map<String, dynamic> json) => ResumoHome(
        repetidas: json['repetidas'] as int? ?? 0,
        faltantes: json['faltantes'] as int? ?? 0,
      );
}
