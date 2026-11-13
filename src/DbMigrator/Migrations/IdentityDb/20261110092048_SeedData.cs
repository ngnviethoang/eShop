using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace DbMigrator.Migrations.IdentityDb
{
    /// <inheritdoc />
    public partial class SeedData : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("""
                INSERT INTO "AspNetUsers" (
                    "Id",
                    "AccessFailedCount",
                    "CardHolderName",
                    "CardNumber",
                    "CardType",
                    "City",
                    "ConcurrencyStamp",
                    "Country",
                    "Email",
                    "EmailConfirmed",
                    "Expiration",
                    "LastName",
                    "LockoutEnabled",
                    "LockoutEnd",
                    "Name",
                    "NormalizedEmail",
                    "NormalizedUserName",
                    "PasswordHash",
                    "PhoneNumber",
                    "PhoneNumberConfirmed",
                    "SecurityNumber",
                    "SecurityStamp",
                    "State",
                    "Street",
                    "TwoFactorEnabled",
                    "UserName",
                    "ZipCode"
                )
                VALUES
                    (
                        '942a6802-0716-4295-957c-f2ccba8c2a06',
                        0,
                        'Alice Smith',
                        'XXXXXXXXXXXX1881',
                        1,
                        'Redmond',
                        'a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d',
                        'U.S.',
                        'AliceSmith@email.com',
                        TRUE,
                        '12/24',
                        'Smith',
                        TRUE,
                        NULL,
                        'Alice',
                        'ALICESMITH@EMAIL.COM',
                        'ALICE',
                        'AQAAAAIAAYagAAAAENBVchoPqsQhxm9GxnMiR3rt40b38yPyZw+aUzXvnCiPs6UAsica/rR0xLedG7658g==',
                        '1234567890',
                        FALSE,
                        '123',
                        '7E9A4B2F1C3D4E5F8A9B0C1D2E3F4A5B',
                        'WA',
                        '15703 NE 61st Ct',
                        FALSE,
                        'alice',
                        '98052'
                    ),
                    (
                        '7a0bae32-bf07-44f6-9a4d-23f217bcd5c3',
                        0,
                        'Bob Smith',
                        'XXXXXXXXXXXX1881',
                        1,
                        'Redmond',
                        'b2c3d4e5-f6a7-4b8c-9d0e-1f2a3b4c5d6e',
                        'U.S.',
                        'BobSmith@email.com',
                        TRUE,
                        '12/24',
                        'Smith',
                        TRUE,
                        NULL,
                        'Bob',
                        'BOBSMITH@EMAIL.COM',
                        'BOB',
                        'AQAAAAIAAYagAAAAEG3hV2I0usXc0i6UW45yFrzm6id517dN6RqsgWeny7iNTxerH2t6xJGxZwA6k5qbCg==',
                        '1234567890',
                        FALSE,
                        '456',
                        '9C1E3A5B7D9F4B2C8E0A1F2E3D4C5B6A',
                        'WA',
                        '15703 NE 61st Ct',
                        FALSE,
                        'bob',
                        '98052'
                    )
                ON CONFLICT DO NOTHING;
                """);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("""
                DELETE FROM "AspNetUsers"
                WHERE "Id" IN (
                    '942a6802-0716-4295-957c-f2ccba8c2a06',
                    '7a0bae32-bf07-44f6-9a4d-23f217bcd5c3'
                );
                """);
        }
    }
}
