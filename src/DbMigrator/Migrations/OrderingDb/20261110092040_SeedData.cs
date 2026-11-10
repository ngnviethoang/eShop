using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace DbMigrator.Migrations.OrderingDb
{
    /// <inheritdoc />
    public partial class SeedData : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("""
                INSERT INTO ordering.cardtypes ("Id", "Name")
                VALUES
                    (1, 'Amex'),
                    (2, 'Visa'),
                    (3, 'MasterCard')
                ON CONFLICT ("Id") DO NOTHING;
                """);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("""
                DELETE FROM ordering.cardtypes
                WHERE "Id" IN (1, 2, 3);
                """);
        }
    }
}
