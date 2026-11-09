# eShop DbMigrator

Standalone database migration runner for eShop using **Entity Framework Core (EF Core)**.

All migrations for all services are centralized in `DbMigrator` under `Migrations/<DatabaseDb>/`.

---

## Architecture & How It Works

1. **Centralized Migrations:** All EF Core migration files are located directly inside `DbMigrator/Migrations/`:
   - `Migrations/CatalogDb/` (`CatalogContext`)
   - `Migrations/IdentityDb/` (`ApplicationDbContext`)
   - `Migrations/OrderingDb/` (`OrderingContext`)
   - `Migrations/WebhooksDb/` (`WebhooksContext`)
2. **Project References:** `DbMigrator` references each domain / API project (`Catalog.API`, `Identity.API`, `Ordering.Infrastructure`, `Webhooks.API`) to compile and apply migrations against their DbContext models.
3. **Execution Modes:**
   - **Console Runner (Programmatic):** Calling `dotnet run` (or running in Docker / Aspire) runs `DbMigrator.Program`, which iterates through each DbContext and executes `await context.Database.MigrateAsync()` with Polly resilience retry (`5s`, `10s`, `20s`).
   - **EF Core CLI (`dotnet ef database update`):** Directly apply migrations from the command line using the EF Core CLI tools.
4. **Tracking:** Completed migrations are tracked natively in PostgreSQL's standard `__EFMigrationsHistory` table.

---

## Developer Workflow

### 1. Add Migration
Run from the repository root:

```powershell
dotnet ef migrations add <MigrationName> `
  --project src/DbMigrator/DbMigrator.csproj `
  --startup-project src/DbMigrator/DbMigrator.csproj `
  --context <DbContext> `
  --output-dir Migrations/<TargetDb>
```

*Example for CatalogDb:*
```powershell
dotnet ef migrations add AddNewProductField `
  --project src/DbMigrator/DbMigrator.csproj `
  --startup-project src/DbMigrator/DbMigrator.csproj `
  --context CatalogContext `
  --output-dir Migrations/CatalogDb
```

*(See [`script.txt`](./script.txt) for ready-to-use commands for CatalogDb, IdentityDb, OrderingDb, and WebhooksDb).*

### 2. Apply Migrations (EF Core Update)

#### Option A: Using EF Core CLI (`database update`)
```powershell
dotnet ef database update `
  --project src/DbMigrator/DbMigrator.csproj `
  --startup-project src/DbMigrator/DbMigrator.csproj `
  --context <DbContext>
```

#### Option B: Run DbMigrator Console App
Applies pending migrations to all 4 databases with retry resilience:
```powershell
cd src/DbMigrator
dotnet run --no-launch-profile
```

### 3. List Migrations
Check applied and pending migrations:
```powershell
dotnet ef migrations list `
  --project src/DbMigrator/DbMigrator.csproj `
  --startup-project src/DbMigrator/DbMigrator.csproj `
  --context <DbContext>
```

### 4. Remove Last Migration (Before applying)
```powershell
dotnet ef migrations remove `
  --project src/DbMigrator/DbMigrator.csproj `
  --startup-project src/DbMigrator/DbMigrator.csproj `
  --context <DbContext>
```

---

## Docker Execution

```powershell
docker build -f src/DbMigrator/Dockerfile -t eshop-dbmigrator .
docker run --rm `
  -e ConnectionStrings__CatalogDB="<ConnStr>" `
  -e ConnectionStrings__IdentityDB="<ConnStr>" `
  -e ConnectionStrings__OrderingDB="<ConnStr>" `
  -e ConnectionStrings__WebhooksDB="<ConnStr>" `
  eshop-dbmigrator
```

> [!NOTE]
> PostgreSQL requires the `pgvector` extension enabled for `CatalogDB` (e.g. `ankane/pgvector` or `pgvector/pgvector:pg16-trixie`).
