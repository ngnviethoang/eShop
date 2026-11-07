using DbMigrator;
using DbUp;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Polly;

var builder = Host.CreateApplicationBuilder(args);
var app = builder.Build();
ILogger logger = app.Services.GetRequiredService<ILoggerFactory>().CreateLogger("DbMigrator");

var connectionStrings = builder.Configuration.GetSection("ConnectionStrings").GetChildren();
foreach (var section in connectionStrings)
{
    var name = section.Key;
    var connectionString = section.Value;
    var scriptPrefix = $".Scripts.{name}.";
    logger.LogInformation("Migrating {DatabaseName}...", name);
    Policy.Handle<Exception>().WaitAndRetry(
        [
            TimeSpan.FromSeconds(5),
            TimeSpan.FromSeconds(10),
            TimeSpan.FromSeconds(20)
        ],
        (exception, timeSpan, retryCount, context) =>
        {
            logger.LogWarning(exception, "[Retry {RetryCount}] Migration failed: {Message}. Retrying in {Seconds}s...", retryCount, exception.Message,
                timeSpan.TotalSeconds);
        }).Execute(() =>
        {
            EnsureDatabase.For.PostgresqlDatabase(connectionString);
            var upgrader = DeployChanges.To
                .PostgresqlDatabase(connectionString)
                .WithScriptsEmbeddedInAssembly(AssemblyReference.Assembly, scriptName => scriptName.Contains(scriptPrefix, StringComparison.OrdinalIgnoreCase))
                .WithTransactionPerScript()
                .LogTo(logger)
                .LogToTrace()
                .WithVariablesDisabled()
                .Build();

            var result = upgrader.PerformUpgrade();
            if (!result.Successful)
            {
                throw new InvalidOperationException($"Error upgrading {name}: {result.Error.Message}", result.Error);
            }

            logger.LogInformation("Successfully migrated database: {DatabaseName}", name);
        }
    );
}

logger.LogInformation("Database migration process completed successfully.");
