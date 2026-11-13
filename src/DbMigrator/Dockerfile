FROM mcr.microsoft.com/dotnet/aspnet:10.0-alpine AS base
RUN apk add --no-cache icu-libs
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false
USER $APP_UID
WORKDIR /app

FROM mcr.microsoft.com/dotnet/sdk:10.0-alpine AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src

# Copy central build configuration files
COPY ["Directory.Build.props", "./"]
COPY ["Directory.Build.targets", "./"]
COPY ["Directory.Packages.props", "./"]
COPY ["nuget.config", "./"]

# Copy project files for layer-cached restore
COPY ["src/DbMigrator/DbMigrator.csproj", "src/DbMigrator/"]
COPY ["src/Catalog.API/Catalog.API.csproj", "src/Catalog.API/"]
COPY ["src/Identity.API/Identity.API.csproj", "src/Identity.API/"]
COPY ["src/Ordering.Infrastructure/Ordering.Infrastructure.csproj", "src/Ordering.Infrastructure/"]
COPY ["src/Ordering.Domain/Ordering.Domain.csproj", "src/Ordering.Domain/"]
COPY ["src/Webhooks.API/Webhooks.API.csproj", "src/Webhooks.API/"]
COPY ["src/eShop.ServiceDefaults/eShop.ServiceDefaults.csproj", "src/eShop.ServiceDefaults/"]
COPY ["src/EventBusRabbitMQ/EventBusRabbitMQ.csproj", "src/EventBusRabbitMQ/"]
COPY ["src/EventBus/EventBus.csproj", "src/EventBus/"]
COPY ["src/IntegrationEventLogEF/IntegrationEventLogEF.csproj", "src/IntegrationEventLogEF/"]

RUN dotnet restore "src/DbMigrator/DbMigrator.csproj"

# Copy source code for required projects
COPY ["src/DbMigrator/", "src/DbMigrator/"]
COPY ["src/Catalog.API/", "src/Catalog.API/"]
COPY ["src/Identity.API/", "src/Identity.API/"]
COPY ["src/Ordering.Infrastructure/", "src/Ordering.Infrastructure/"]
COPY ["src/Ordering.Domain/", "src/Ordering.Domain/"]
COPY ["src/Webhooks.API/", "src/Webhooks.API/"]
COPY ["src/eShop.ServiceDefaults/", "src/eShop.ServiceDefaults/"]
COPY ["src/EventBusRabbitMQ/", "src/EventBusRabbitMQ/"]
COPY ["src/EventBus/", "src/EventBus/"]
COPY ["src/IntegrationEventLogEF/", "src/IntegrationEventLogEF/"]
COPY ["src/Shared/", "src/Shared/"]

WORKDIR "/src/src/DbMigrator"
FROM build AS publish
ARG BUILD_CONFIGURATION=Release
RUN dotnet publish "DbMigrator.csproj" -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "DbMigrator.dll"]
