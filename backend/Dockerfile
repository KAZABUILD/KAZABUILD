FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src
COPY . .
RUN dotnet restore "KAZABUILD.API/KAZABUILD.API.csproj"
RUN dotnet publish "KAZABUILD.API/KAZABUILD.API.csproj" -c Release -o /app/publish

FROM mcr.microsoft.com/dotnet/aspnet:9.0
WORKDIR /app
COPY --from=build /app/publish .
ENV ASPNETCORE_URLS=http://0.0.0.0:5000
EXPOSE 5000
CMD ["dotnet", "KAZABUILD.API.dll"]