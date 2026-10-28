namespace CompletaJaApp.Controllers.Api
{
    // DTOs = formato exato do JSON que entra e sai da API.
    // Nunca devolvemos as entidades do EF direto, para não vazar SenhaHash, CPF etc.
    // O ASP.NET converte os nomes para camelCase no JSON (Nome -> "nome").

    // ---------- Auth ----------
    public record LoginRequest(string? Email, string? Senha);
    public record UsuarioDto(int Id, string Nome, string FotoUrl);
    public record LoginResponse(string Token, UsuarioDto Usuario);

    // ---------- Home ----------
    public record HomeDto(string Nome, string FotoUrl, int Repetidas, int Faltantes);

    // ---------- Álbuns ----------
    public record AlbumDto(int Id, string Nome, string CapaUrl, int Total, int UsuariosVinculados);
    public record AlbumCatalogoDto(int Id, string Nome, string CapaUrl, int Total, int UsuariosVinculados, bool JaColeciona);

    // ---------- Figurinhas ----------
    public record AlbumResumoDto(int Id, string Nome, string CapaUrl);
    public record FigurinhaDto(string Codigo, string Nome, int Quantidade);
    public record FigurinhasAlbumDto(
        AlbumResumoDto Album,
        int Total,
        int Unicas,
        int Faltantes,
        int Progresso,
        List<FigurinhaDto> Figurinhas);
    public record SalvarFigurinhaRequest(int Quantidade, string? Nome);
}
