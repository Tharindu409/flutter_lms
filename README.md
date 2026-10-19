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

2. Install dependencies:
   flutter pub get

3. Start an Android emulator, then run the app:     
   flutter run


## Project Status

| Day | Focus | Status |
|-----|-------|--------|
| 1 | Setup, project initialization, Login UI | Done |
| 2 | Navigation, forms, validation, theme | Pending |
| 3 | Splash, onboarding, role dashboards | Pending |
| 4 | Docker backend, Postman, core API setup | Pending |
| 5 | Authentication, sessions, profiles | Pending |
| 6 | Courses, enrollment, lessons, progress | Pending |
| 7 | Quizzes, assignments, reviews, notifications | Pending |
| 8 | Instructor course building | Pending |
| 9 | Admin, state management, navigation | Pending |
| 10 | Responsive design, testing, final submission | Pending |

## Daily Progress

### Day 1
- Set up Flutter, Android SDK and Android emulator (`flutter doctor` reports no issues)
- Created the Flutter project and ran it on the emulator
- Built the shared Login UI (email, password with show/hide toggle, login button)
- Created the GitHub repository and README

## Commit Convention

This project follows Conventional Commits, for example:
`feat(auth): add login screen ui`, `docs: update README`, `fix(ui): fix button alignment`.
