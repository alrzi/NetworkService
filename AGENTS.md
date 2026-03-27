# AGENTS.md

## Project Overview

Swift Package for network requests with authorization support, retry logic, and interceptors. Two modules:
- **NetworkServiceDomain** — public protocols, models, error types. Zero dependencies.
- **NetworkService** — internal implementations. Public API exposed only via `NetworkService` factory.

Swift 6.0 · iOS 16+ · macOS 13+ · watchOS 9+

## Build / Lint / Test

```bash
swift build                              # build all targets
swift build -c release                   # release build
swift package clean                      # clean

swift test                               # run all tests
swift test --filter NetworkServiceTests  # run one test suite
```

SwiftLint runs automatically as a build plugin — no manual step needed.
**Strict mode is on**: every warning is treated as an error.

## Architecture

```
Sources/
├── NetworkServiceDomain/
│   ├── Auth/
│   │   ├── AuthToken.swift              # Token entity
│   │   ├── AuthServiceProtocol.swift    # TokenRefreshing protocol
│   │   ├── TokenStorageProtocol.swift   # Token storage protocol
│   │   └── UserSession.swift            # SessionCredentialsProvider + UserSessionProtocol
│   ├── Errors/
│   │   ├── NetworkError.swift           # Network error types
│   │   └── NetworkError+Mapping.swift   # Error mapping
│   ├── Extensions/
│   │   ├── JSONDecoder+snakeCaseIsoDateDecoder.swift
│   │   └── URLResponse+Validate.swift
│   ├── Interceptors/
│   │   └── RequestInterceptor.swift     # RequestInterceptor protocol
│   ├── Models/
│   │   ├── Auth/
│   │   │   ├── TokenResponse.swift      # Ответ при обновлении токена
│   │   │   └── SessionStatus.swift      # Состояние сессии пользователя
│   │   ├── Errors/
│   │   │   └── RequestConvertibleError.swift  # Ошибки создания URLRequest
│   │   └── Request/
│   │       └── RetryDecision.swift      # Решение о повторной попытке
│   ├── Request/
│   │   ├── DecoderProviding.swift
│   │   ├── HTTPMethod.swift
│   │   ├── RequestConvertible.swift
│   │   ├── RequestProtocol.swift
│   │   └── URLRequestWrapper.swift
│   └── NetworkClientProtocol.swift
│
└── NetworkService/
    ├── Auth/
    │   ├── RefreshTokenRequest.swift    # Refresh token request
    │   └── TokenRefresher.swift         # Token refresher implementation
    ├── Interceptors/
    │   ├── AuthHeaderHelper.swift       # Хелпер для заголовков авторизации
    │   ├── AuthInterceptor.swift        # Авторизация с обновлением токена
    │   ├── ConnectivityInterceptor.swift
    │   ├── LoggingInterceptor.swift
    │   └── TokenInterceptor.swift       # Авторизация без обновления токена
    ├── SessionManager/
    │   └── SessionManager.swift         # Session manager (uses SessionCredentialsProvider)
    ├── Storage/
    │   ├── TokenStorage.swift           # Keychain storage
    │   └── TokenStorageProtocol+Tokens.swift
    ├── UserSession/
    │   └── UserSession.swift            # UserSession implementation
    ├── NetworkClient.swift
    └── NetworkServiceContainer.swift    # Factory + AuthorizationMode
```

### Key Design Patterns

**AuthorizationMode** — enum для настройки авторизации:
- `.disabled` — авторизация не требуется
- `.enabled(sessionProvider:refreshTokenRequestFactory:)` — полная авторизация с обновлением токена
- `.tokenOnly(sessionProvider:)` — только токен, без обновления

**SessionCredentialsProvider** — протокол для сетевого слоя (доступ к токенам):
- `getValidToken() async -> AuthToken?`
- `updateToken(_ newToken: AuthToken) async`
- `notifyInvalidToken() async`

**UserSessionProtocol** — протокол для подписок на статус сессии:
- `status: CurrentValueAsyncSequenceReadOnly<SessionStatus>`
- `setSession(token:) async`
- `logout() async`

**Single Source of Truth**: `UserSession` — единственный источник правды для работы с токенами. Все операции (сохранение, чтение, удаление) проходят через `UserSession`.

## Code Style

### Language — Russian

All doc comments, inline comments, log messages, and test descriptions are in Russian.

### File Header

```swift
//
//  FileName.swift
//  ModuleName
//
//  Created by Name on DD.MM.YYYY.
//
```

### Imports — Not Sorted

`sorted_imports` is disabled. Order: Apple frameworks, third-party, internal modules. No blank lines.

### Formatting

- **4-space indentation** (error-level).
- **Line length**: 180 chars max.
- **Uncuddled else** — `else` / `catch` on a new line:
  ```swift
  if condition {
  }
  else {
  }

  do {
      try something()
  }
  catch {
      handleError()
  }
  ```
- **Trailing commas** allowed in multiline parameter lists (`trailing_comma` disabled).
- **`where` clause** on the line after `)`:
  ```swift
  func make<ID>() -> some NetworkServiceProtocol<ID>
  where ID: ProductIdentifier {
  ```
- **Vertical whitespace** between enum/switch cases (enforced, error-level):
  ```swift
  switch value {
  case .a:
      break

  case .b:
      break
  }
  ```
- **Trailing whitespace**: `ignores_empty_lines: true` — пустые строки игнорируются, на непустых строках пробелы в конце запрещены (error-level).
- **No whitespace** after opening braces or before closing braces.
- **Implicit return** in single-expression closures and computed properties.
- **Shorthand optional binding**: `if let value { }` not `if let value = value { }`.

### Type Contents Order (Enforced)

1. `case` → 2. `associatedtype` → 3. `typealias` → 4. type properties → 5. type methods → 6. instance properties → 7. `subscript` → 8. `init` → 9. instance methods → 10. nested types → 11. `deinit`

### Types and Naming

- **Protocols**: `-ing` suffix for capabilities (`NetworkServiceManaging`, `RequestIntercepting`).
- **Caseless enums** as namespaces: `enum API { }`, `enum NetworkService { }`.
- **Structs** for stateless features / value types.
- **`final class`** for stateful managers — never non-final.
- **Private extensions** for file-scoped helpers.

### Concurrency

- `async/await` everywhere — no Combine, no completion handlers.
- All protocols and types conform to `Sendable`.
- `any Protocol` for stored existentials; `some Protocol` in parameters and return types.
- Background tasks: `Task<(), any Error>`, cancelled in `deinit`.

Error types are `public enum X: Error, Sendable` with associated values.

### Logging

Logger injected via `init`, specialized with a metadata key:
```swift
var logger = logger
logger[metadataKey: "service"] = "NetworkService"
self.logger = logger
```

## Key SwiftLint Limits

| Metric | Warning | Error |
|---|---|---|
| Line length | 180 | — |
| File length | 500 | 600 |
| Type body | 350 | 350 |
| Function body | 120 | 200 |
| Closure body | 50 | 60 |
| Function params | 8 | 10 |
| Tuple size | 4 | 4 |
| Identifier length | 1–50 | 1–60 |
| Type name length | 2–65 | 2–65 |
| Generic type name | 25 | 30 |

## Testing

Tests use **Swift Testing** framework (`import Testing`). No Quick, Nimble, or Cuckoo.

### Structure

- **`@Suite("описание на русском")`** on a `struct`, with `.serialized` trait when sequential execution is needed.
- **`@Test("описание на русском")`** on each test method.
- **`// Given` / `// When` / `// Then`** comment markers structure every test.
- **Parameterized tests** via `arguments:` on `@Test`.

```swift
@Suite("SessionManager тесты", .serialized)
struct SessionManagerTests {
    @Test("Конкурентные запросы при истекшем токене — только один вызов refreshToken")
    func concurrentRequestsWhenTokenExpired() async {
        // Given
        let storage = MockTokenStorage()
        // When
        let token = try? await sessionManager.getValidToken()
        // Then
        #expect(token == "new_access_token", "должен быть успех")
    }
}
```

### Assertions

- **`#expect(condition, "message на русском")`** for assertions.
- **`Issue.record("message")`** instead of `XCTFail`.
- **`switch` on `Result`** to verify `.success` / `.failure` cases.

### Mocks

Hand-written mocks — `final class` conforming to protocol with `@unchecked Sendable`:
```swift
final class TokenRefresher: TokenRefreshing, @unchecked Sendable {
    private(set) var refreshTokenCallCount = 0
    var refreshTokenResult: Result<TokenResponse, NetworkError> = .success(...)
    func refreshToken(_ refreshToken: String) async throws(NetworkError) -> TokenResponse {
        refreshTokenCallCount += 1
        return try refreshTokenResult.get()
    }
}
```

- Helper types (`MockTokenStorage`, `TokenRefresher`) are `private` or nested in the test struct.
- Factory methods are `private static func` on the test struct.
