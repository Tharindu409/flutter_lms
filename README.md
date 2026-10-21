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


