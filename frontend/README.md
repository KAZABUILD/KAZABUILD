# frontend

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## How to run
 - `cd frontend` in the terminal to access the project
 - `flutter pub get` to get packages
 - `flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:5000` to run chrome website
 - `flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:5000` to run android emulator app
 - `flutter build web --release --dart-define=API_BASE_URL=https://api.yourdomain.com` to run production version

## Flutter Packages:
- `dio`
- `flutter_riverpod`
- `flutter_dotenv`
- `json_annotation`
- `build_runner`
- `json_serializable`

## Features

## Webpages