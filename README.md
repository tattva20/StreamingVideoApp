# StreamingVideoApp

<p align="center">
  <img src="https://img.shields.io/badge/Platform-iOS%2015%2B-blue.svg" alt="Platform: iOS 15+">
  <img src="https://img.shields.io/badge/Swift-5.9-orange.svg" alt="Swift 5.9">
  <img src="https://img.shields.io/badge/Xcode-16-blue.svg" alt="Xcode 16">
  <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License: MIT">
</p>

<p align="center">
  <a href="https://github.com/tattva20/StreamingVideoApp/actions/workflows/CI-iOS.yml">
    <img src="https://github.com/tattva20/StreamingVideoApp/actions/workflows/CI-iOS.yml/badge.svg" alt="CI-iOS">
  </a>
  <a href="https://github.com/tattva20/StreamingVideoApp/actions/workflows/CI-macOS.yml">
    <img src="https://github.com/tattva20/StreamingVideoApp/actions/workflows/CI-macOS.yml/badge.svg" alt="CI-macOS">
  </a>
</p>

<p align="center">
  A production-ready iOS video streaming application built with <strong>Test-Driven Development (TDD)</strong>, <strong>SOLID principles</strong>, and <strong>Clean Architecture</strong>.
</p>

---

## Overview

StreamingVideoApp demonstrates professional iOS development practices with a modular, testable architecture that scales from small features to enterprise-level applications.

### Key Highlights

- **100% TDD** - Every feature developed test-first
- **Clean Architecture** - Clear separation of concerns across modules
- **SOLID Principles** - Maintainable, extensible codebase
- **Comprehensive Testing** - Unit, Integration, and End-to-End tests
- **CI/CD Ready** - GitHub Actions with ThreadSanitizer

---

## Features

### Video Feed
- Paginated video list with infinite scroll
- Pull-to-refresh functionality
- Lazy image loading with caching
- Error handling with retry mechanism

### Video Player
- Full-featured AVPlayer implementation
- Play/Pause with elegant UI
- Seek forward/backward (10 seconds)
- Progress bar with time display
- Volume control with mute toggle
- Playback speed (0.5x, 1x, 1.25x, 1.5x, 2x)
- Fullscreen mode with orientation support
- Picture-in-Picture (PiP) support
- Auto-hiding controls overlay

### Video Comments
- Threaded comment display
- Pull-to-refresh for latest comments
- Relative timestamp formatting

### Offline Support
- CoreData persistence for video metadata
- Image caching for offline viewing
- Cache-first loading strategy with remote fallback

---

## Architecture

StreamingVideoApp follows a **modular Clean Architecture** with strict layer boundaries:

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│                      StreamingVideoApp                          │
│                    (Composition Root)                           │
│                                                                 │
│   Responsibilities:                                             │
│   • Dependency injection & wiring                               │
│   • Platform-specific implementations (AVPlayer)                │
│   • App lifecycle management                                    │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│                      StreamingCoreiOS                           │
│                    (iOS UI Components)                          │
│                                                                 │
│   Responsibilities:                                             │
│   • UIKit view controllers                                      │
│   • Table/Collection view cells                                 │
│   • UI layout and animations                                    │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│                       StreamingCore                             │
│                 (Platform-Agnostic Core)                        │
│                                                                 │
│   Responsibilities:                                             │
│   • Domain models (Video, VideoComment)                         │
│   • Use cases (Load, Cache, Validate)                           │
│   • Presenters and ViewModels                                   │
│   • Network and storage abstractions                            │
│                                                                 │
│   ⚠️  NO UIKit/AppKit imports allowed                           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Module Structure

```
StreamingVideoApp.xcworkspace/
│
├── StreamingCore/                      # Core business logic
│   ├── StreamingCore/                  # Main framework
│   │   ├── Video Feature/              # Domain models
│   │   ├── Video API/                  # Remote data loading
│   │   ├── Video Cache/                # Local persistence
│   │   ├── Video Presentation/         # Presenters & ViewModels
│   │   ├── Video Playback Feature/     # Player protocol
│   │   └── Video Comments Feature/     # Comments domain
│   │
│   ├── StreamingCoreiOS/               # iOS UI layer
│   │   ├── Video UI/                   # Video list components
│   │   ├── Video Player UI/            # Player controls
│   │   └── Video Comments UI/          # Comments UI
│   │
│   └── Tests/
│       ├── StreamingCoreTests/
│       ├── StreamingCoreiOSTests/
│       ├── StreamingCoreAPIEndToEndTests/
│       └── StreamingCoreCacheIntegrationTests/
│
├── StreamingVideoApp/                  # iOS App target
│   ├── StreamingVideoApp/
│   │   ├── SceneDelegate.swift         # Main composition
│   │   ├── AVPlayerVideoPlayer.swift   # AVPlayer implementation
│   │   └── Composers/                  # Feature composers
│   │
│   └── StreamingVideoAppTests/         # Integration tests
│
└── .github/workflows/                  # CI/CD
    ├── CI-iOS.yml
    └── CI-macOS.yml
```

### Design Patterns

| Pattern | Usage |
|---------|-------|
| **Composition Root** | All dependencies wired in `SceneDelegate` |
| **Decorator** | `VideoLoaderCacheDecorator` adds caching |
| **Composite** | `VideoLoaderComposite` for fallback loading |
| **Adapter** | Connects domain to presentation layer |
| **Factory** | Creates complex object graphs |
| **Strategy** | Interchangeable loading strategies |

---

## Getting Started

### Requirements

- **Xcode 16.0+**
- **iOS 15.0+**
- **Swift 5.9+**

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/tattva20/StreamingVideoApp.git
   cd StreamingVideoApp
   ```

2. **Open the workspace**
   ```bash
   open StreamingVideoApp.xcworkspace
   ```

3. **Select scheme and run**
   - Choose `StreamingVideoApp` scheme
   - Select a simulator or device
   - Press `Cmd + R` to run

### Running Tests

```bash
# Run all tests
xcodebuild test \
  -workspace StreamingVideoApp.xcworkspace \
  -scheme StreamingVideoApp \
  -destination 'platform=iOS Simulator,name=iPhone 15'

# Run with ThreadSanitizer (CI mode)
xcodebuild clean build test \
  -workspace StreamingVideoApp.xcworkspace \
  -scheme "CI_iOS" \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO \
  -sdk iphonesimulator \
  -destination "platform=iOS Simulator,name=iPhone 15" \
  -enableThreadSanitizer YES
```

---

## Testing Strategy

### Test Pyramid

```
                    ╱╲
                   ╱  ╲
                  ╱ E2E╲           End-to-End Tests
                 ╱──────╲          (Real API)
                ╱        ╲
               ╱Integration╲       Integration Tests
              ╱────────────╲       (Composed systems)
             ╱              ╲
            ╱   Unit Tests   ╲     Unit Tests
           ╱──────────────────╲    (Isolated components)
```

### Test Categories

| Category | Location | Description |
|----------|----------|-------------|
| **Unit** | `StreamingCoreTests/` | Test single units with mocks |
| **iOS Unit** | `StreamingCoreiOSTests/` | Test UI components |
| **Integration** | `StreamingVideoAppTests/` | Test composed systems |
| **API E2E** | `StreamingCoreAPIEndToEndTests/` | Test against real API |
| **Cache Integration** | `StreamingCoreCacheIntegrationTests/` | Test real CoreData |

### Test Coverage Focus

- **Presenters** - Business logic and state management
- **Use Cases** - Loading, caching, validation flows
- **Mappers** - JSON parsing and data transformation
- **View Controllers** - User interaction handling
- **Composers** - Dependency wiring

---

## CI/CD

### GitHub Actions Workflows

| Workflow | Trigger | Description |
|----------|---------|-------------|
| **CI-iOS** | Push/PR to main | Full test suite on iOS Simulator |
| **CI-macOS** | Push/PR to main | Platform-agnostic tests (faster) |

### CI Features

- **ThreadSanitizer** - Detects data races and threading issues
- **Parallel Testing** - Faster CI feedback
- **Code Coverage** - Track test coverage metrics
- **Multiple Xcode Versions** - Fallback Xcode selection

---

## API

### Backend

The app connects to a custom API hosted on GitHub Pages:

| Endpoint | Description |
|----------|-------------|
| `GET /api/v1/videos` | Paginated video list |
| `GET /api/v1/videos/{id}/comments` | Video comments |
| `GET /api/v1/videos/{id}/image` | Video thumbnail |

### Sample Response

```json
{
  "items": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "title": "Big Buck Bunny",
      "description": "A large rabbit deals with three bullying rodents.",
      "image_url": "https://example.com/thumbnail.jpg",
      "video_url": "https://example.com/video.mp4"
    }
  ]
}
```

---

## Development

### TDD Workflow

```
1. RED    → Write a failing test
2. GREEN  → Write minimum code to pass
3. REFACTOR → Clean up while tests pass
```

### Adding New Features

1. **Define Protocol** in `StreamingCore`
2. **Write Tests** for the protocol
3. **Implement** the minimum code
4. **Create UI** in `StreamingCoreiOS`
5. **Wire Up** in composition root
6. **Add Integration Tests**

### Code Style

- Swift standard naming conventions
- Protocol-oriented design
- Dependency injection over singletons
- Value types where appropriate
- Clear, descriptive naming

---

## Project History

This project was developed following TDD principles from the ground up:

1. **Foundation** - Core video loading with cache
2. **Remote API** - HTTPClient and video mapping
3. **Persistence** - CoreData integration
4. **UI Layer** - Videos list with pagination
5. **Video Player** - Full-featured playback
6. **Comments** - Video comments feature
7. **PiP** - Picture-in-Picture support
8. **CI/CD** - GitHub Actions automation

---

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Write tests first (TDD)
4. Implement the feature
5. Ensure all tests pass
6. Commit your changes (`git commit -m 'Add amazing feature'`)
7. Push to the branch (`git push origin feature/amazing-feature`)
8. Open a Pull Request

### Contribution Guidelines

- Follow TDD - no untested code
- Maintain Clean Architecture boundaries
- Use meaningful commit messages
- Update documentation as needed

---

## Resources

- [Essential Feed Case Study](https://github.com/essentialdevelopercom/essential-feed-case-study) - Architectural inspiration
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html) - Robert C. Martin
- [TDD By Example](https://www.amazon.com/Test-Driven-Development-Kent-Beck/dp/0321146530) - Kent Beck

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## Author

**Octavio Rojas**

---

<p align="center">
  Built with TDD and Clean Architecture
</p>
