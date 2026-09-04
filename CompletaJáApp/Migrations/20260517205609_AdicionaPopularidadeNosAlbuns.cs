using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace CompletaJáApp.Migrations
{
    /// <inheritdoc />
    public partial class AdicionaPopularidadeNosAlbuns : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "UsuariosVinculados",
                table: "Albuns",
                type: "int",
                nullable: false,
                defaultValue: 0);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "UsuariosVinculados",
                table: "Albuns");
        }
    }
}
