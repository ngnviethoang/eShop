# eShop DbMigrator

Standalone database migration runner for eShop using **DbUp** (`dbup-postgresql`).

---

## How It Works

1. **Auto Discovery:** Dynamically reads all target databases from `ConnectionStrings` in `appsettings.json`.
2. **Resilience:** Uses Polly (`WaitAndRetry`: 5s, 10s, 20s) to handle database cold-starts and connection delays.
3. **Execution:** Discovers and applies embedded SQL scripts from `Scripts/<DatabaseDB>/` in alphabetical order.
4. **Transaction Safety:** Executes each script in its own transaction (`.WithTransactionPerScript()`).
5. **Tracking:** Records completed migrations in PostgreSQL's `schemaversions` table.

---

## Developer Workflow

### 1. Add Migration
Create the EF Core migration from the repo root:
```powershell
dotnet ef migrations add <Name> `
  --project <Project.csproj> --startup-project <Startup.csproj> `
  --context <DbContext> --output-dir <OutputDir>
```

### 2. Export SQL to DbMigrator
Export SQL with `--idempotent` and `--no-transactions` (DbUp manages the transaction):
```powershell
dotnet ef migrations script <From> <To> `
  --project <Project.csproj> --startup-project <Startup.csproj> `
  --context <DbContext> `
  --output src/DbMigrator/Scripts/<DatabaseDB>/<MigrationName>.sql `
  --idempotent --no-transactions
```
*(Check [`script.txt`](./script.txt) for ready-to-use commands for CatalogDB, IdentityDB, OrderingDB, and WebhooksDB).*

### 3. Apply Migrations
```powershell
cd src/DbMigrator
dotnet run --no-launch-profile
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
> PostgreSQL requires the `pgvector` extension enabled for `CatalogDB` (e.g. `pgvector/pgvector:pg16-trixie`).
