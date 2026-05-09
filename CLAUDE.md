# Claude Coding Guide (lets_jam_app)

This repository is the **Flutter mobile app** for end-users of the starter kit. It is the **user-facing client** — admins use the Nuxt web panel instead. The app follows strict Clean Architecture with BLoC for state management.

---

## Stack

- **Flutter** (Dart SDK ^3.7.2)
- **BLoC** (`flutter_bloc ^8.1.4`) — state management
- **GetIt + Injectable** — dependency injection and service locator
- **Dio** — HTTP client
- **Pusher Channels Flutter** (`pusher_channels_flutter ^2.0.3`) — real-time
- **Dartz** — functional error handling (`Either<Failure, T>`)
- **Freezed + json_serializable** — immutable models and JSON serialization
- **Equatable** — value equality for entities
- **sqflite + shared_preferences** — local persistence

---

## Directory Structure

```
lib/
  main.dart
  core/
    config/
      api_config.dart       ← base URL and endpoint constants
      pusher_config.dart    ← Pusher credentials
    di/                     ← GetIt setup (injectable-generated)
    error/                  ← Failure classes, exceptions
    network/
      network_info.dart     ← connectivity interface
      network_info_impl.dart
    routes/                 ← named route definitions
    services/               ← cross-feature singletons (e.g. token storage)
    usecases/               ← base UseCase interface

  features/
    auth/
      data/
        datasources/        ← remote + local datasource implementations
        models/             ← JSON-serializable models (extend entities)
        repositories/       ← repository implementations
        services/           ← auth-specific service helpers
      domain/
        entities/           ← pure Dart classes (no Flutter, no Dio)
        repositories/       ← repository interfaces
        usecases/           ← LoginUseCase, RegisterUseCase, VerifyEmailUseCase
      presentation/
        bloc/               ← AuthBloc, AuthEvent, AuthState
        pages/              ← login page, register page, verify email page
    chat/
      data/
        models/
        repositories/
        services/
      domain/
        repositories/
        usecases/
      presentation/
        bloc/
        pages/
        widgets/
    home/
      presentation/
        pages/
    splash/
      presentation/
        pages/
```

---

## Architecture Rules (non-negotiable)

### Layer boundaries

```
Presentation  → BLoC → domain UseCases → domain Repository interface
Data layer    → implements domain Repository interface, uses datasources/Dio
```

- **Entities** (`domain/entities/`) are pure Dart — no json_serializable, no Flutter imports.
- **Models** (`data/models/`) extend or map to entities and carry `fromJson`/`toJson` via `json_serializable` or `freezed`.
- **UseCases** take a repository interface, not an implementation.
- **BLoC** calls use cases, never repositories directly.
- **Presentation** only imports BLoC/Cubit and domain entities — never data classes.

### Error handling (Dartz)

All repository methods and use cases return `Either<Failure, T>`. Never `throw` from a use case — return `Left(failure)`.

```dart
// use case signature
Future<Either<Failure, User>> call(LoginParams params);

// bloc handling
result.fold(
  (failure) => emit(AuthError(failure.message)),
  (user)    => emit(AuthSuccess(user)),
);
```

Define `Failure` subclasses in `core/error/` (e.g. `ServerFailure`, `NetworkFailure`, `CacheFailure`).

### Dependency injection

Use `@injectable` + `@lazySingleton` / `@singleton` annotations. Run code generation after adding/changing injectable classes:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Register the DI container in `core/di/injection.dart` and call `configureDependencies()` in `main.dart`.

---

## API Integration

### Base URL
`http://localhost:8006/api`  (defined in `core/config/api_config.dart`)

### Auth
- `POST /api/login` → `{ user, token }`
- `POST /api/register`
- `POST /api/verify-email`
- Token stored via `shared_preferences` and injected into Dio headers via an interceptor.

### Dio interceptor pattern
The auth interceptor reads the stored token and adds `Authorization: Bearer {token}` to every request. It also handles 401 → logout.

### Response shapes
```dart
// success
{ "user": { ... }, "token": "..." }         // login
{ "success": true, "data": { ... } }        // general

// error
{ "message": "...", "errors": { ... } }     // 422
{ "message": "..." }                        // 401 / 403
```

Always parse error responses and map them to `Failure` types, never let raw `DioException` reach the BLoC.

---

## Real-Time (Pusher)

Pusher credentials are in `core/config/pusher_config.dart`. The `PusherChannelsFlutter` client is a singleton registered via GetIt.

Pattern for subscribing in a BLoC or service:
```dart
await pusher.subscribe(
  channelName: 'private-chat.$chatId',
  onEvent: (event) {
    // parse event.data and add to stream/bloc
  },
);
```

Call `pusher.unsubscribe(channelName: ...)` when the corresponding BLoC is closed.

---

## Coding Conventions

- All Dart files use strict null safety (`sdk: ^3.7.2`).
- Prefer `freezed` for events, states, and value objects that need equality + copyWith.
- BLoC state classes must be `Equatable` or `freezed`.
- Use `bloc_test` for bloc unit tests, `mocktail` for mocking dependencies.
- Keep widgets small; extract into `widgets/` subdirectory when a widget exceeds ~100 lines.
- Name files in `snake_case`, classes in `PascalCase`.

---

## Adding a New Feature

1. Create folder `lib/features/<feature_name>/` with `data/`, `domain/`, `presentation/` subdirectories.
2. Define entities in `domain/entities/`.
3. Define repository interface in `domain/repositories/`.
4. Write use cases in `domain/usecases/` returning `Either<Failure, T>`.
5. Implement models in `data/models/` with `json_serializable`.
6. Implement repository in `data/repositories/`.
7. Create BLoC in `presentation/bloc/`.
8. Build pages in `presentation/pages/`.
9. Register new injectables and run `build_runner`.
10. Add route in `core/routes/`.

---

## Running the App

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs   # after model/DI changes
flutter run                                                        # starts on connected device/emulator
flutter test                                                       # unit + widget tests
```

---

## What This App Does NOT Do

- No admin functionality — that belongs to the Nuxt web panel.
- No direct DB access — everything goes through the backend API.
- No mutations to audit logs — the app never calls audit write endpoints.
