FROM mcr.microsoft.com/dotnet/aspnet:10.0-alpine AS base
RUN apk add --no-cache icu-libs
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false
USER $APP_UID
WORKDIR /app
EXPOSE 8080

FROM mcr.microsoft.com/dotnet/sdk:10.0-alpine AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src

# Copy central build configuration files
COPY ["Directory.Build.props", "./"]
COPY ["Directory.Build.targets", "./"]
COPY ["Directory.Packages.props", "./"]
COPY ["nuget.config", "./"]

# Copy project files for layer-cached restore
COPY ["src/WebhookClient/WebhookClient.csproj", "src/WebhookClient/"]
COPY ["src/eShop.ServiceDefaults/eShop.ServiceDefaults.csproj", "src/eShop.ServiceDefaults/"]

RUN dotnet restore "src/WebhookClient/WebhookClient.csproj"

# Copy source code for required projects
COPY ["src/WebhookClient/", "src/WebhookClient/"]
COPY ["src/eShop.ServiceDefaults/", "src/eShop.ServiceDefaults/"]

WORKDIR "/src/src/WebhookClient"
FROM build AS publish
ARG BUILD_CONFIGURATION=Release
RUN dotnet publish "WebhookClient.csproj" -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "WebhookClient.dll"]
