FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build

WORKDIR /src

COPY ["CompletaJáApp/CompletaJáApp.csproj", "CompletaJáApp/"]

RUN dotnet restore "CompletaJáApp/CompletaJáApp.csproj"

COPY . .

WORKDIR "/src/CompletaJáApp"

RUN dotnet publish "CompletaJáApp.csproj" \
    -c Release \
    -o /app/publish \
    --no-restore \
    /p:UseAppHost=false


FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS final

WORKDIR /app

COPY --from=build /app/publish .

EXPOSE 10000

CMD ["sh", "-c", "exec dotnet CompletaJáApp.dll --urls http://0.0.0.0:${PORT:-10000}"]