# Development Environment Setup

## Prerequisites
- [Docker Desktop](https://www.docker.com/products/docker-desktop) (for running the stack)
- [.NET 8 SDK](https://dotnet.microsoft.com/en-us/download)
- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Visual Studio Code](https://code.visualstudio.com/)
- [Android Studio](https://developer.android.com/studio)
- Recommended VS Code extensions:
  - `Dart-Code.dart-code`
  - `Dart-Code.flutter`
  - `ms-dotnettools.csharp`

### macOS Setup Notes
- Use Docker Desktop for MSSQL, RabbitMQ, and Jenkins
- Install Homebrew: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
- Install RabbitMQ: `brew install rabbitmq`
- Install .NET SDK: `https://dotnet.microsoft.com/en-us/download`
- Install Flutter SDK: `https://docs.flutter.dev/get-started/install/macos`

### Alternative Windows Setup
If you prefer to install dependencies using [Chocolatey](https://chocolatey.org/), run PowerShell as Administrator and execute:
- Install .NET 8 SDK:
  - `choco install dotnet-8.0-sdk -y`
- Install Flutter:
  - `choco install flutter -y`
- Install Docker Desktop:
  - `choco install docker-desktop -y`
- Install RabbitMQ:
  - `choco install rabbitmq -y`
- Install Jenkins:
  - `choco install jenkins -y`

## Project Setup without Docker

### Backend Setup
1. Navigate to backend folder in terminal:
 - `cd backend/KAZABUILD.API`
 - `dotnet restore`
 - `dotnet watch run`
2. API will run on http://localhost:5000.

### Frontend Setup
1. Navigate to frontend folder:
 - `cd frontend`
 - `flutter pub get`
 - `flutter run -d chrome`
2. The web app will run on http://localhost:3000 (or another free port).

### RabbitMQ Setup
1. Install Erlang:
 - `https://www.erlang.org/downloads`
2. Install RabbitMQ:
 - Windows Installer: 
   - `https://www.rabbitmq.com/docs/install-windows`
 - Or run in Docker: 
   - `docker-compose up rabbitmq`
3. Management UI: http://localhost:15672
 - Default user: guest / guest

### Jenkins Setup
1. Install Jenkins:
 - Installer: 
   - `https://www.jenkins.io/download`
 - Or run in Docker:
   - `docker-compose up jenkins`
2. Management UI: http://localhost:8080
 - Follow the setup wizard and install suggested plugins

## Full Stack with Docker
1. Start all services:
 - `docker-compose up --build`

## Services available:
 - `Backend API: http://localhost:5000`
 - `Backend Swagger Documentation: http://localhost:5000/Swagger`
 - `Frontend Web: http://localhost:3000`
 - `RabbitMQ UI: http://localhost:15672`
 - `Jenkins: http://localhost:8080`