# 🚀 Flutter Template Quick Start Guide

This guide will walk you through setting up your project using this boilerplate. Follow these steps in order to rename the project, generate features, and manage assets.

---

## 📋 Prerequisites

Before starting, ensure you have the following installed:
- **Flutter SDK** (3.x recommended)
- **Dart SDK**
- **LCOV** (Optional, for test coverage reports)
    - macOS: `brew install lcov`
    - Linux: `sudo apt-get install lcov`

---

## 🏁 Step 1: Clone and Setup

First, clone the repository and navigate to the project root:

```bash
git clone <your-repo-url> my_new_app
cd my_new_app
chmod +x scripts/setup.sh
./scripts/setup.sh
```

---

## 🔄 Step 2: Rename the Project

Use the production-ready shell script to change the app name and package ID (bundle identifier) across all platforms (Android, iOS, Web, Desktop).

**Command:**
```bash
# Usage: ./scripts/rename.sh "Display Name" com.company.app
chmod +x scripts/rename.sh
./scripts/rename.sh "My Amazing App" com.mycompany.amazingapp
```

**What this does:**
- Updates `pubspec.yaml` name and description.
- Changes Android `applicationId`, `namespace`, and folder structure.
- Updates iOS/macOS Bundle IDs and App Names in `Info.plist`.
- Refactors all Dart imports to use the new package name.
- Cleans up old directories safely.

---

## 🛠 Step 3: Generate a New Feature

Follow the **Feature-First Architecture** by generating a new module. Our custom Dart script creates the entire folder structure and boilerplate code.

**Command:**
```bash
# Usage: dart run scripts/generate.dart feature <name>
dart run scripts/generate.dart feature auth
```

**Folder structure created:**
- `lib/features/auth/auth_screen.dart` (UI)
- `lib/features/auth/providers/auth_provider.dart` (Logic)
- `lib/features/auth/repository/auth_repository.dart` (Data)
- `lib/features/auth/models/auth_model.dart` (Model)

---

## 🧩 Step 4: Generate a Core Service

Generate a core service under `lib/core/services/` (Riverpod + Talker boilerplate).

**Command:**
```bash
# Usage: dart run scripts/generate.dart service <name>
dart run scripts/generate.dart service auth
```

**File created:**
- `lib/core/services/auth_service.dart`

**Note (legacy):**
- You can still run `dart run scripts/generate_service.dart auth`, but it now forwards to the unified generator.

---

## ⚡ Step 5: Code Generation

Since we use `freezed` and `riverpod_generator`, you must run the build runner to generate the `.g.dart` and `.freezed.dart` files.

**Command:**
```bash
# Run once
dart run build_runner build -d

# Or watch for changes
dart run build_runner watch -d
```

---

## 🎨 Step 6: Generate App Icons

Ensure you have a source icon (recommended 1024x1024px) at the path specified in `flutter_launcher_icons.yaml`.

**Command:**
```bash
chmod +x scripts/generate_icons.sh
./scripts/generate_icons.sh
```

---

## 🧪 Step 7: Testing and Coverage

Run your tests and generate an HTML coverage report to see which parts of your code are tested.

**Commands:**
```bash
chmod +x scripts/run_tests.sh

# Run all tests with HTML report
./scripts/run_tests.sh

# Run tests for a specific feature without coverage
./scripts/run_tests.sh --target test/features/auth/ --no-coverage
```

The HTML report will be available at `coverage/html/index.html`.

---

## 🌐 Step 8: Environment Configuration

The project uses `--dart-define` to manage environment variables like API URLs. This allows you to switch between Dev and Prod environments without changing the code.

### ⚙️ Setting up Android Studio / IntelliJ
1. Click on the **Main.dart** dropdown (near the Run button) -> **Edit Configurations...**.
2. In the **Additional run args** field, paste:
   ```text
   --dart-define=API_BASE_URL=[https://api.yourdomain.com/](https://api.yourdomain.com/)
   ```

---

## 🌍 Localization (i18n)

This project uses [slang](https://pub.dev/packages/slang) for strict, type-safe translations and standard `flutter_localizations` for system widgets.

### Managing Languages (CLI)

We provide a handy script to easily set up or add new languages to your project. Run the following command in your terminal:

```bash
dart run scripts/add_language.dart
```

* **First run:** The script will ask for your base language code (e.g., `en`, `uk`) and set up the initial configuration and base translation file.
* **Subsequent runs:** It will ask for a new language code, generate the corresponding translation file, and update the classes automatically.

### How to manually update translations:

1. Open the JSON translation files located in `lib/i18n/`.
2. Add or modify your key-value pairs in the base file (`strings.i18n.json`) and corresponding locale files (e.g., `strings_uk.i18n.json`).
3. Run the slang generator to update the Dart classes:

```bash
dart run slang watch
```

### Usage in code:

**Inside UI Widgets (Reactive to locale changes):**
```dart
@override
Widget build(BuildContext context) {
  final t = Translations.of(context);
  
  return Text(t.home.title); // Remember to return the widget!
}
```

**Inside Business Logic / Providers (No BuildContext required):**
```dart
// Access the global 't' variable generated by slang
final errorMessage = t.errors.network;
```

---

## 📂 Project Structure Overview

- **lib/core**: Global infrastructure (API clients, cache, logging via Talker).
- **lib/shared**: Reusable UI components (Theme, buttons, custom dialogs via Toastification).
- **lib/features**: Business logic isolated by domain.
- **scripts/**: Automation tools for development.

---

## ✅ Final Verification

After all steps, verify the app status:
1. `flutter clean`
2. `flutter pub get`
3. `flutter run`

**Happy Coding!** 🚀