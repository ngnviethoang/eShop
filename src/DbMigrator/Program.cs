using DbMigrator;
using eShop.Catalog.API.Infrastructure;
using eShop.Identity.API.Data;
using eShop.Ordering.Infrastructure;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Npgsql.EntityFrameworkCore.PostgreSQL.Infrastructure;
using Polly;
using Webhooks.API.Infrastructure;

var builder = Host.CreateApplicationBuilder(args);

var dbContextMappings = new Dictionary<Type, string>
{
    { typeof(CatalogContext), "CatalogDB" },
    { typeof(ApplicationDbContext), "IdentityDB" },
    { typeof(OrderingContext), "OrderingDB" },
    { typeof(WebhooksContext), "WebhooksDB" }
};

var migrationsAssembly = typeof(AssemblyReference).Assembly.FullName;

RegisterDbContext<CatalogContext>(npgsql => npgsql.UseVector());
RegisterDbContext<ApplicationDbContext>();
RegisterDbContext<OrderingContext>();
RegisterDbContext<WebhooksContext>();

var app = builder.Build();
var logger = app.Services.GetRequiredService<ILoggerFactory>().CreateLogger("DbMigrator");

var retryPolicy = Policy.Handle<Exception>()
    .WaitAndRetryAsync(
        [
            TimeSpan.FromSeconds(5),
            TimeSpan.FromSeconds(10),
            TimeSpan.FromSeconds(20)
        ],
        (exception, timeSpan, retryCount, _) =>
        {
            logger.LogWarning(exception, "[Retry {RetryCount}] Migration failed: {Message}. Retrying in {Seconds}s...",
                retryCount, exception.Message, timeSpan.TotalSeconds);
        });

foreach (var (contextType, dbName) in dbContextMappings)
{
    await retryPolicy.ExecuteAsync(async () =>
    {
        using var scope = app.Services.CreateScope();
        var context = (DbContext)scope.ServiceProvider.GetRequiredService(contextType);
        logger.LogInformation("Migrating {DatabaseName}...", dbName);
        await context.Database.MigrateAsync();
        logger.LogInformation("Successfully migrated {DatabaseName}.", dbName);
    });
}

logger.LogInformation("Database migration process completed successfully.");
return;

void RegisterDbContext<TContext>(Action<NpgsqlDbContextOptionsBuilder>? configureNpgsql = null) where TContext : DbContext
{
    var connectionKey = dbContextMappings[typeof(TContext)];
    var connStr = builder.Configuration.GetConnectionString(connectionKey)
                  ?? throw new InvalidOperationException($"Connection string '{connectionKey}' was not found in configuration.");

    builder.Services.AddDbContext<TContext>((sp, options) =>
    {
        options.UseNpgsql(connStr, npgsql =>
        {
            npgsql.MigrationsAssembly(migrationsAssembly);
            configureNpgsql?.Invoke(npgsql);
        });
    });
}
