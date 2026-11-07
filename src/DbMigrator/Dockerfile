FROM mcr.microsoft.com/dotnet/runtime:10.0-alpine AS base
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
RUN dotnet restore "src/DbMigrator/DbMigrator.csproj"

# Copy source code
COPY ["src/DbMigrator/", "src/DbMigrator/"]

WORKDIR "/src/src/DbMigrator"
FROM build AS publish
ARG BUILD_CONFIGURATION=Release
RUN dotnet publish "DbMigrator.csproj" -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "DbMigrator.dll"]
