#Build stage
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS dev
WORKDIR /app

#Copy csproj files and restore first (layer caching)
COPY ./KAZABUILD.Domain/*.csproj ./KAZABUILD.Domain/
COPY ./KAZABUILD.Application/*.csproj ./KAZABUILD.Application/
COPY ./KAZABUILD.Infrastructure/*.csproj ./KAZABUILD.Infrastructure/
COPY ./KAZABUILD.API/*.csproj ./KAZABUILD.API/
RUN dotnet restore KAZABUILD.API

# opy rest of the source code
COPY . .

# Install dotnet watch tool
RUN dotnet tool install --global dotnet-watch
ENV PATH="$PATH:/root/.dotnet/tools"

# Expose the dev port
EXPOSE 5000

# Run in hot reload mode
CMD ["dotnet", "watch", "run", "--project", "KAZABUILD.API", "--urls", "http://0.0.0.0:5000"]