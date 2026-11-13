# AGENTS.md — Fast Codebase Navigation & Architecture Guide

> **Purpose:** Read this file first before scanning directories or running broad searches. It maps every microservice, entry point, database context, integration event flow, and architectural rule in the repository.
> **Related Docs:** See [`ARCHITECTURE.md`](ARCHITECTURE.md) for deep-dive system diagrams, sequence flows, and design patterns, and [`plans/aws-migration-plan.md`](plans/aws-migration-plan.md) for the AWS cloud migration roadmap.

---

## 1. Core Stack & Repository Conventions

* **Runtime & SDK:** .NET 10 (`net10.0`), C# 13 (`global.json`).
* **Central Package Management (CPM):** All NuGet package versions are defined centrally in `Directory.Packages.props`. **Never** add `Version="..."` attributes to `<PackageReference>` inside `.csproj` files.
* **Solution Files:**
  * `eShop.Web.slnf`: **Use this for CLI builds & tests** (excludes `.NET MAUI` mobile projects that require extra workloads).
  * `eShop.slnx`: Full XML solution including `ClientApp` and `HybridApp`.
* **Active Initiative (`migration-aws` branch):** Refactoring from local sample to production-grade **AWS Cloud Architecture** (ECS Fargate ARM64, RDS PostgreSQL, ElastiCache Redis, Amazon MQ, API Gateway + YARP BFF) while keeping **.NET Aspire (`eShop.AppHost`)** for local orchestration. See [`plans/aws-migration-plan.md`](plans/aws-migration-plan.md) for full task status.

---

## 2. Quick Lookup: "Where is X?" (Zero-Search Index)

| Task / Feature | Exact File Path(s) |
| :--- | :--- |
| **Local Orchestration (Containers, Env Vars, Wiring)** | `src/eShop.AppHost/AppHost.cs`, `src/eShop.AppHost/Extensions.cs` |
| **Health Checks (`/health`, `/alive`), OpenTelemetry, Service Discovery** | `src/eShop.ServiceDefaults/Extensions.cs` |
| **JWT / Bearer Auth Validation for Backend APIs** | `src/eShop.ServiceDefaults/AuthenticationExtensions.cs` |
| **Internal API Gateway / YARP Routing & Clusters** | `src/eShop.Gateway/Program.cs`, `src/eShop.Gateway/appsettings.json` |
| **Centralized EF Core Migrations & SQL Seed Data** | `src/DbMigrator/Program.cs`, `src/DbMigrator/Migrations/{CatalogDb,IdentityDb,OrderingDb,WebhooksDb}/` |
| **Catalog REST Endpoints & Semantic AI Vector Search** | `src/Catalog.API/Apis/CatalogApi.cs`, `src/Catalog.API/Services/CatalogAI.cs` |
| **Basket gRPC Service & Redis Storage** | `src/Basket.API/Proto/basket.proto`, `src/Basket.API/Grpc/BasketService.cs`, `src/Basket.API/Repositories/RedisBasketRepository.cs` |
| **Ordering REST Endpoints, CQRS Commands & Queries** | `src/Ordering.API/Apis/OrdersApi.cs`, `src/Ordering.API/Application/Commands/`, `src/Ordering.API/Application/Queries/OrderQueries.cs` |
| **Ordering Domain Aggregates (`Order`, `Buyer`)** | `src/Ordering.Domain/AggregatesModel/OrderAggregate/Order.cs`, `src/Ordering.Domain/AggregatesModel/BuyerAggregate/Buyer.cs` |
| **OIDC Clients, Scopes & Duende IdentityServer Setup** | `src/Identity.API/Program.cs`, `src/Identity.API/Configuration/Config.cs` |
| **Storefront UI (Blazor Server), OIDC Login & HTTP/gRPC Clients** | `src/WebApp/Program.cs`, `src/WebApp/Extensions/Extensions.cs`, `src/WebApp/Components/` |
| **Storefront Product Image URL Resolution** | `src/WebApp/Services/ProductImageUrlProvider.cs` |
| **Real-Time Order Status Notifications in Blazor UI** | `src/WebApp/Services/OrderStatus/OrderStatusNotificationService.cs` |
| **RabbitMQ EventBus & Consumer Channel Lifecycle** | `src/EventBusRabbitMQ/RabbitMQEventBus.cs`, `src/EventBusRabbitMQ/RabbitMqDependencyInjectionExtensions.cs` |
| **Transactional Outbox (`IntegrationEventLog`)** | `src/IntegrationEventLogEF/Services/IntegrationEventLogService.cs`, `src/IntegrationEventLogEF/Utilities/ResilientTransaction.cs` |

---

## 3. Project-by-Project Breakdown (`src/`)

### A. Orchestration, Gateway & Shared Infrastructure
1. **`src/eShop.AppHost`** — .NET Aspire local orchestrator.
   * `AppHost.cs`: Defines Redis (`redis`), RabbitMQ (`eventbus`), PostgreSQL (`postgres` using `ankane/pgvector:latest` with 4 DBs: `CatalogDb`, `IdentityDb`, `OrderingDb`, `WebhooksDb`), `db-migrator`, and all service projects.
   * `Extensions.cs`: Helper methods for AI provisioning (`AddFoundry`, `AddOllama`) and YARP configuration.
2. **`src/eShop.ServiceDefaults`** — Shared foundational library referenced by all services.
   * `Extensions.cs`: `AddServiceDefaults()`, `ConfigureOpenTelemetry()`, `AddDefaultHealthChecks()`, `MapDefaultEndpoints()`.
   * `AuthenticationExtensions.cs`: `AddDefaultAuthentication()` reading `Identity:Url` and `Authentication:Schemes:Bearer`.
   * `HttpClientExtensions.cs`: `AddAuthToken()` delegating handler to forward Bearer tokens on outgoing `HttpClient` / gRPC calls.
3. **`src/eShop.Gateway`** — Standalone YARP Reverse Proxy / BFF.
   * `Program.cs` & `appsettings.json`: Routes `/api/catalog/{**catch-all}`, `/api/orders/{**catch-all}`, `/api/basket/{**catch-all}`, `/BasketApi.Basket/{**catch-all}` (HTTP/2 gRPC), and `/api/webhooks/{**catch-all}` to internal services (`*.eshop.local:8080` in AWS or Aspire service discovery in Dev).
4. **`src/EventBus` & `src/EventBusRabbitMQ`** — Pub/Sub messaging abstraction and RabbitMQ implementation.
   * `RabbitMQEventBus.cs`: Declares topic exchange `eshop_event_bus`, binds service queue (`SubscriptionClientName`), serializes/deserializes events via `System.Text.Json` source generation (`EventBusSubscriptionInfo.JsonSerializerOptions`).
5. **`src/IntegrationEventLogEF`** — EF Core Transactional Outbox table (`IntegrationEventLog`).
   * Used by `Catalog.API` and `Ordering.API` to save integration events atomically inside the same DB transaction before publishing to RabbitMQ.

---

### B. Backend Microservices & Background Workers
1. **`src/Catalog.API`** (Minimal API + EF Core PostgreSQL + `pgvector`)
   * **Entry & DI:** `Program.cs`, `Extensions/Extensions.cs` (`AddApplicationServices`).
   * **Endpoints:** `Apis/CatalogApi.cs` (v1 & v2 API versions under `/api/catalog`).
   * **Database:** `Infrastructure/CatalogContext.cs` (Entity configs in `Infrastructure/EntityConfigurations/`).
   * **AI / Vectors:** `Services/CatalogAI.cs` generates `Vector` (384 dimensions) from item name/description.
   * **Outbox:** `IntegrationEvents/CatalogIntegrationEventService.cs`.
2. **`src/Basket.API`** (gRPC + StackExchange.Redis)
   * **Entry & DI:** `Program.cs`, `Extensions/Extensions.cs`.
   * **Contract & Handler:** `Proto/basket.proto`, `Grpc/BasketService.cs` (`GetBasket`, `UpdateBasket`, `DeleteBasket`).
   * **Storage:** `Repositories/RedisBasketRepository.cs` (stores JSON under `/basket/{id}`).
3. **`src/Identity.API`** (ASP.NET Core MVC + ASP.NET Core Identity + Duende IdentityServer)
   * **Entry & Config:** `Program.cs`, `Configuration/Config.cs` (defines API scopes `basket`, `orders`, `webhooks` and clients `webapp`, `webhooksclient`, `maui`, `*swaggerui`).
   * **Database:** `Data/ApplicationDbContext.cs`, `Models/ApplicationUser.cs`.
   * **Controllers:** `Quickstart/Account/AccountController.cs`.
4. **`src/Ordering.API`, `src/Ordering.Domain`, `src/Ordering.Infrastructure`** (DDD + CQRS + MediatR)
   * **Endpoints:** `Ordering.API/Apis/OrdersApi.cs` (`/api/orders`).
   * **MediatR Pipeline Behaviors:** `Ordering.API/Application/Behaviors/` (`LoggingBehavior`, `ValidatorBehavior`, `TransactionBehavior` — commits `OrderingContext` and publishes outbox events).
   * **Commands & Handlers:** `Ordering.API/Application/Commands/` (`CreateOrderCommandHandler`, `CancelOrderCommandHandler`, `ShipOrderCommandHandler`, `SetStockConfirmedOrderStatusCommandHandler`, `SetPaidOrderStatusCommandHandler`, etc.). with Idempotency via `IdentifiedCommandHandler` & `Ordering.Infrastructure/Idempotency/RequestManager.cs`.
   * **Domain Model:** `Ordering.Domain/AggregatesModel/OrderAggregate/Order.cs` and `BuyerAggregate/Buyer.cs`.
   * **Database:** `Ordering.Infrastructure/OrderingContext.cs` (schema: `ordering`).
5. **`src/OrderProcessor`** (Background Worker)
   * `Services/GracePeriodManagerService.cs`: Polls `ordering.orders` via Npgsql for orders whose `GracePeriodTime` has elapsed and publishes `GracePeriodConfirmedIntegrationEvent`.
6. **`src/PaymentProcessor`** (Background Worker)
   * `IntegrationEvents/EventHandling/OrderStatusChangedToStockConfirmedIntegrationEventHandler.cs`: Simulates payment check and publishes `OrderPaymentSucceededIntegrationEvent` or `OrderPaymentFailedIntegrationEvent`.
7. **`src/Webhooks.API`** (Minimal API + EF Core PostgreSQL)
   * **Endpoints:** `Apis/WebHooksApi.cs` (`/api/webhooks`).
   * **Database:** `Infrastructure/WebhooksContext.cs`.
   * **Dispatch:** `Services/WebhooksSender.cs` & `Services/WebhooksRetriever.cs`.

---

### C. Frontend Applications
1. **`src/WebApp` & `src/WebAppComponents`** (Blazor Web App — Interactive Server)
   * **Entry & DI:** `WebApp/Program.cs`, `WebApp/Extensions/Extensions.cs` (registers OIDC cookie auth, `BasketService` gRPC client, `CatalogService` HTTP client, `OrderingService` HTTP client, AI `ChatState`).
   * **Pages:** `WebApp/Components/Pages/` (`Catalog/`, `Cart/`, `Checkout/`, `Orders/`, `User/`).
2. **`src/WebhookClient`** (Blazor Server Demo Receiver)
   * `Program.cs`, `Endpoints/WebhookEndpoints.cs`, `Services/WebHooksClient.cs`.
3. **`src/ClientApp` & `src/HybridApp`** (.NET MAUI Mobile/Desktop clients — excluded from `eShop.Web.slnf`).

---

## 4. Database & EF Core Migration Rules (CRITICAL)

* **NO Runtime Migrations in APIs:** API microservices (`Catalog.API`, `Identity.API`, `Ordering.API`, `Webhooks.API`) **do not** run `Database.MigrateAsync()` or seed data on startup.
* **Single Source of Migrations (`src/DbMigrator`):**
  All EF Core migrations and `*ModelSnapshot.cs` files live inside `src/DbMigrator/Migrations/` and each API's `UseNpgsql` sets `MigrationsAssembly("DbMigrator")`:

| Database Key | `DbContext` Class | Source Project | Migrations Folder in `src/DbMigrator` |
| :--- | :--- | :--- | :--- |
| `CatalogDB` | `CatalogContext` | `src/Catalog.API` | `Migrations/CatalogDb` |
| `IdentityDB` | `ApplicationDbContext` | `src/Identity.API` | `Migrations/IdentityDb` |
| `OrderingDB` | `OrderingContext` | `src/Ordering.Infrastructure` | `Migrations/OrderingDb` |
| `WebhooksDB` | `WebhooksContext` | `src/Webhooks.API` | `Migrations/WebhooksDb` |

* **Adding a New Migration (Run from repo root):**
  ```powershell
  dotnet ef migrations add <MigrationName> `
    --project src/DbMigrator/DbMigrator.csproj `
    --startup-project src/DbMigrator/DbMigrator.csproj `
    --context <CatalogContext|ApplicationDbContext|OrderingContext|WebhooksContext> `
    --output-dir Migrations/<CatalogDb|IdentityDb|OrderingDb|WebhooksDb>
  ```
  See `src/DbMigrator/README.md` and `src/DbMigrator/script.txt` for full CLI reference.

---

## 5. End-to-End Order Lifecycle & Integration Event Map

When tracing bugs or modifying order workflows, follow this exact event chain across services:

1. **Checkout Initiated (`WebApp` $\rightarrow$ `Ordering.API`):**
   * `WebApp/Services/BasketState.cs` calls `OrderingService.CreateOrder()` (`POST /api/orders`).
   * `Ordering.API` handles `CreateOrderCommand` $\rightarrow$ saves `Order` (`Submitted`) $\rightarrow$ publishes **`OrderStartedIntegrationEvent`** + **`OrderStatusChangedToSubmittedIntegrationEvent`**.
2. **Basket Cleared (`Basket.API`):**
   * `Basket.API` handles `OrderStartedIntegrationEvent` (`OrderStartedIntegrationEventHandler.cs`) $\rightarrow$ deletes user's basket in Redis.
3. **Grace Period Elapsed (`OrderProcessor` $\rightarrow$ `Ordering.API`):**
   * `OrderProcessor` (`GracePeriodManagerService.cs`) detects elapsed grace period $\rightarrow$ publishes **`GracePeriodConfirmedIntegrationEvent`**.
   * `Ordering.API` handles `GracePeriodConfirmedIntegrationEvent` $\rightarrow$ dispatches `SetAwaitingValidationOrderStatusCommand` $\rightarrow$ publishes **`OrderStatusChangedToAwaitingValidationIntegrationEvent`**.
4. **Stock Validation (`Catalog.API` $\rightarrow$ `Ordering.API`):**
   * `Catalog.API` handles `OrderStatusChangedToAwaitingValidationIntegrationEvent` $\rightarrow$ checks `AvailableStock` in `CatalogContext` $\rightarrow$ publishes **`OrderStockConfirmedIntegrationEvent`** (or **`OrderStockRejectedIntegrationEvent`**).
   * `Ordering.API` handles stock confirmation $\rightarrow$ dispatches `SetStockConfirmedOrderStatusCommand` $\rightarrow$ publishes **`OrderStatusChangedToStockConfirmedIntegrationEvent`**.
5. **Payment Processing (`PaymentProcessor` $\rightarrow$ `Ordering.API`):**
   * `PaymentProcessor` handles `OrderStatusChangedToStockConfirmedIntegrationEvent` $\rightarrow$ publishes **`OrderPaymentSucceededIntegrationEvent`** (or **`OrderPaymentFailedIntegrationEvent`**).
   * `Ordering.API` handles payment success $\rightarrow$ dispatches `SetPaidOrderStatusCommand` $\rightarrow$ publishes **`OrderStatusChangedToPaidIntegrationEvent`**.
6. **Side Effects on Paid (`Catalog.API`, `Webhooks.API`, `WebApp`):**
   * `Catalog.API` deducts stock (`OrderStatusChangedToPaidIntegrationEventHandler.cs`).
   * `Webhooks.API` dispatches outbound HTTP webhooks to registered subscribers.
   * `WebApp` updates real-time UI state via `OrderStatusNotificationService.cs` on every `OrderStatusChangedTo*` event.

---

## 6. Build, Test & Verification Commands

* **Build Server & Web Solution (Fastest):**
  ```powershell
  dotnet build eShop.Web.slnf
  ```
* **Build a Single Service:**
  ```powershell
  dotnet build src/<ServiceName>/<ServiceName>.csproj
  ```
* **Run Unit & Functional Tests:**
  ```powershell
  dotnet test --solution eShop.Web.slnf
  ```
  *Note: `*.FunctionalTests` projects use `Microsoft.AspNetCore.Mvc.Testing` and Testcontainers/Aspire testing harnesses (requires Docker running).*
  *Run pure unit tests only (no Docker required):*
  ```powershell
  dotnet test src/../tests/Ordering.UnitTests/Ordering.UnitTests.csproj
  dotnet test src/../tests/Basket.UnitTests/Basket.UnitTests.csproj
  dotnet test src/../tests/Application.UnitTests/Application.UnitTests.csproj
  ```
* **Run Full Stack Locally via Aspire:**
  ```powershell
  aspire run
  ```
