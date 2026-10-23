# Flutter LMS Mobile App

A Flutter mobile application for a Learning Management System (LMS) with
three role-based interfaces: **Student**, **Instructor** and **Admin**.
The app connects to a Dockerized backend API (integration starts on Day 4).

## Prerequisites

- Flutter SDK 3.47.7 (stable) and Dart SDK
- Android Studio with an Android emulator
- VS Code or Android Studio
- Git and a GitHub account
- Docker Desktop and Postman (needed from Day 4)

## Getting Started

1. Clone the repository: git clone https://github.com/Tharindu409/flutter_lms

cd flutter_lms

2. Install dependencies: flutter pub get

3. Start an Android emulator, then run the app: flutter run

## Backend connection

The shared login form sends `POST /api/v1/auth/login` with an `email` and
`password`. It expects the successful response payload to contain a `user`
object and `tokens.accessToken` / `tokens.refreshToken`. The role on the
returned user selects the matching dashboard; login credentials are not
hardcoded in the app.

The default API address is `http://10.0.2.2:5000` for an Android emulator
connecting to a backend running on the development computer. Override it for
another device or environment with a Dart define, for example:

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.1.20:5000
```

Use the backend host reachable from your device (and HTTPS for deployed
environments). The API base address must not include `/api/v1`; endpoint paths
already include it.


## Project Structure

lib/
  models/      plain Dart data classes
  screens/     full pages
  widgets/     reusable UI components
  services/    API calls, storage, data sources
  providers/   state management (Provider)
  utils/       routes, theme, validators, constants
  main.dart    app entry point

## Project Status

| Day | Focus | Status |
|-----|-------|--------|
| 1 | Setup, project initialization, Login UI | Done |
| 2 | Navigation, forms, validation, theme | Done |
| 3 | Splash, onboarding, role dashboards | Done |
| 4 | Docker backend, Postman, core API setup | Pending |
| 5 | Authentication, sessions, profiles | Pending |
| 6 | Courses, enrollment, lessons, progress | Pending |
| 7 | Quizzes, assignments, reviews, notifications | Pending |
| 8 | Instructor course building | Pending |
| 9 | Admin, state management, navigation | Pending |
| 10 | Responsive design, testing, final submission | Pending |

