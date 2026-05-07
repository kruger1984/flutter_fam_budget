# 🏗 Flutter Project Architecture (Feature-First + Riverpod)

This project follows a strict **Feature-First Architecture** adapted for Flutter using **Riverpod 3.0**. The core goal is simplicity, rapid development, and avoiding the boilerplate of strict Clean Architecture while maintaining high testability and separation of concerns.

---

## 🛠 Tech Stack

- **State Management & DI**: `flutter_riverpod`, `riverpod_annotation`
- **Routing**: `go_router`
- **Networking**: `dio`
- **Models & JSON**: `freezed_annotation`, `json_annotation`
- **Local Storage / Cache**: `shared_preferences`, `flutter_secure_storage`, disk cache (JSON files via `path_provider`)
- **Logging & Error Tracking**: `talker_flutter`
- **UI & Notifications**: `toastification`, `cached_network_image`, `cupertino_icons`

---

## 📂 Directory Structure

```text
lib/
├── core/                # Global infrastructure (NO UI)
│   ├── api/             # Dio client, interceptors (Talker attached)
│   ├── cache/           # SharedPreferences, SecureStorage, File-based cache primitives
│   └── utils/           # Pure helpers, extensions, validators, global logger
│
├── features/            # Isolated business features (Domain logic & UI)
│   └── <feature_name>/
│       ├── providers/   # Riverpod Notifiers (State & Business Logic)
│       ├── repository/  # API calls and Cache handling for this specific feature
│       ├── models/      # Freezed data classes
│       ├── widgets/     # Local UI components (specific to this feature)
│       └── <feature>_screen.dart
│
├── shared/              # Global reusable UI (NO business logic)
│   ├── theme/           # App colors, typography, styles
│   ├── widgets/         # Buttons, Inputs, Loaders
│   └── dialogs/         # Standard alerts, bottom sheets, toastification wrappers
│
└── main.dart            # Entry point, ProviderScope + Overrides + Talker init
```

---

## 1. The Dependency Rule & Flow

Instead of strict inward-pointing layers, we use a unidirectional vertical flow within isolated features, and a composition approach for cross-feature UI.

- **Core Layer**: Global configurations. Knows NOTHING about features.
- **Shared Layer**: Reusable UI components. Knows NOTHING about features or core logic.
- **Repositories**: Know about Core (API/Cache clients) and Models. Do NOT know about Providers or UI.
- **Providers**: Know about Repositories and Models. Do NOT know about UI.
- **UI**: Knows about Providers. Rebuilds reactively.

---

## 2. Layer Breakdown (Inside a Feature)

### A. Repositories (Data Access)
Handles data retrieval and serialization.
- **Rule**: Create universal methods with optional parameters (e.g., `getHabits({String? status})`) instead of multiple UseCases.
- **Error Handling**: Catch `DioException` or parse errors here, log them via `Talker`, and throw standard app exceptions to be caught by the Provider.

### B. Providers (Logic & State)
Replaces "Use Cases" and UI Controllers. Manages state, validation, and processes user actions.
- **Rule**: Use Riverpod Code Generation (`@riverpod`). 
- **Rule**: For UI actions (e.g., saving a form), use a `Notifier` that exposes methods like `saveData()` and updates its internal state (loading, error, success).

### C. Presentation (The UI)
Displays data and delegates events to Providers.
- **Rule**: Keep widgets dumb. Only `ref.watch` for state and `ref.read` for actions.
- **Notifications**: Use `toastification` to show success/error messages based on Provider state changes.

---

## 3. Cross-Feature Communication (Crucial Rules)

When features need to interact, follow these rules:

### 1. Smart UI Composition
If a widget represents a specific domain entity (e.g., `HabitCard`), it **must live inside its domain feature** (`features/habits/widgets/`), even if it is displayed on the `Home` or `Statistics` screen.
- **Aggregator Screens** (like Home or Statistics) simply import and compose these smart widgets. They do not duplicate the logic.

### 2. State Aggregation
If a screen needs to mathematically combine data from multiple features (e.g., Total Score), create an **Aggregator Provider** in the aggregator feature (`features/statistics/providers/`).
- This provider will `ref.watch` the providers from `habits` and `tasks` to calculate the final state.

### 3. Shell & Content Pattern (For Multi-Domain Screens)
When a screen manages multiple entities (e.g., a "Create" screen with Tabs for Habit and Task):
- **The Shell**: Create a dedicated feature for the UI wrapper (e.g., `features/creator/creator_screen.dart`). It only handles UI navigation (TabBar).
- **The Content**: The actual forms (`CreateHabitForm`, `CreateTaskForm`) and their logic live inside their respective domain features (`habits` and `tasks`). The Shell simply imports them.

---

## 4. Key Concepts & Anti-Patterns

### 🚫 No GetIt, No Global Locators
We strictly use **Riverpod** for Dependency Injection. 
Heavy synchronous/asynchronous services (like `SharedPreferences`) are initialized in `main.dart` and injected using `ProviderScope(overrides: [...])`.

### 🚫 No Premature Abstraction (No UseCases)
- Do **not** create `abstract class IRepository` unless you actually have multiple implementations.
- Do **not** create "Use Case" classes. The `Notifier` (Provider) handles the business logic flow.
- Do **not** create "God Object" screens. If a screen is 300+ lines and handles multiple domains, split it using the Shell & Content pattern.

### 📝 Logging & Debugging
- Always use `Talker` for logging instead of `print()` or `debugPrint()`.
- Example: `talker.error('Failed to load habits', exception, stackTrace);`

---

## 5. CLI Generation
To generate a new feature with the correct boilerplate, use the custom Dart script:
```bash
dart run scripts/generate.dart feature <feature_name>
```
This ensures consistent folder structures for Providers, Repositories, Models, and Widgets.