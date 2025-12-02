# Testing Strategy and Scheme Organization

This document explains our test organization strategy, following Essential Feed patterns.

## Test Pyramid

We follow a comprehensive testing approach with multiple test levels:

```
                    E2E Tests (Slowest, Most Integrated)
                   /
          Integration Tests (Medium Speed)
         /
    Unit Tests (Fast, Isolated)
```

## Test Types

### 1. Unit Tests (Fast Feedback Loop)

**Purpose**: Test individual components in isolation

**Schemes**:
- `StreamingCore`: Tests StreamingCore framework (domain logic, API, cache)
- `StreamingCoreiOS`: Tests StreamingCoreiOS framework (UI components, presenters)

**When to Run**: After every code change, before committing

**Speed**: ~1-5 seconds

**Examples**:
- `RemoteVideoLoaderTests`: Tests API client logic with URLProtocolStub
- `LocalVideoLoaderTests`: Tests cache logic with VideoStoreSpy
- `ErrorViewTests`: Tests error UI component behavior
- `ListViewControllerTests`: Tests list UI controller

### 2. Integration Tests (Medium Feedback Loop)

**Purpose**: Test multiple components working together with real infrastructure

**Scheme**: `StreamingCoreCacheIntegrationTests`

**When to Run**: Before pushing, in CI pipeline

**Speed**: ~5-15 seconds

**Examples**:
- `StreamingCoreCacheIntegrationTests`: Tests real CoreData persistence across multiple instances

**Key Characteristics**:
- Uses real CoreData stack (not mocks)
- Tests multiple loader instances to verify persistence
- Tests cache expiration logic
- Verifies data integrity across app restarts

### 3. End-to-End Tests (Comprehensive Validation)

**Purpose**: Test complete system with real backend API

**Scheme**: `StreamingCoreAPIEndToEndTests`

**When to Run**: Before releases, in CI pipeline

**Speed**: ~10-30 seconds (depends on network)

**Examples**:
- `test_endToEndTestServerGETVideosResult_matchesFixedTestAccountData`: Validates entire API contract

**Key Characteristics**:
- Hits real GitHub Pages API
- Uses ephemeral URLSession (no cache pollution)
- Validates exact JSON contract
- Tracks memory leaks

### 4. CI Scheme (Comprehensive Test Suite)

**Purpose**: Run ALL tests for CI/CD and pre-release validation

**Scheme**: `CI_iOS`

**When to Run**:
- In CI/CD pipeline
- Before major releases
- When validating significant refactors
- Not frequently during development (too slow)

**Speed**: ~20-50 seconds (all tests combined)

**Test Targets Included**:
1. StreamingCoreTests (unit tests)
2. StreamingCoreiOSTests (iOS unit tests)
3. StreamingCoreCacheIntegrationTests (integration tests)
4. StreamingCoreAPIEndToEndTests (E2E tests)

**Key Features**:
- ✅ Code coverage enabled
- ✅ Random test execution order (catches test dependencies)
- ✅ Parallel test execution (faster CI runs)
- ✅ CoreData concurrency debugging enabled

## Scheme Configuration Details

### Unit Test Schemes (StreamingCore, StreamingCoreiOS)

```xml
<TestAction
    buildConfiguration = "Debug"
    shouldUseLaunchSchemeArgsEnv = "YES">
    <Testables>
        <TestableReference skipped = "NO">
            <!-- Single test target -->
        </TestableReference>
    </Testables>
</TestAction>
```

**Usage**:
```bash
# Run StreamingCore unit tests
xcodebuild test -project StreamingCore.xcodeproj \
    -scheme StreamingCore \
    -destination 'platform=iOS Simulator,name=iPhone 17'

# Run StreamingCoreiOS unit tests
xcodebuild test -project StreamingCore.xcodeproj \
    -scheme StreamingCoreiOS \
    -destination 'platform=iOS Simulator,name=iPhone 17'
```

### CI Scheme (CI_iOS)

```xml
<TestAction
    buildConfiguration = "Debug"
    codeCoverageEnabled = "YES"
    onlyGenerateCoverageForSpecifiedTargets = "YES">
    <Testables>
        <TestableReference
            skipped = "NO"
            parallelizable = "YES"
            testExecutionOrdering = "random">
            <!-- All test targets -->
        </TestableReference>
    </Testables>
</TestAction>
```

**Usage**:
```bash
# Run ALL tests (CI mode)
xcodebuild test -project StreamingCore.xcodeproj \
    -scheme CI_iOS \
    -destination 'platform=iOS Simulator,name=iPhone 17'

# Run with result bundle for detailed analysis
xcodebuild test -project StreamingCore.xcodeproj \
    -scheme CI_iOS \
    -destination 'platform=iOS Simulator,name=iPhone 17' \
    -resultBundlePath ./TestResults.xcresult
```

## Essential Feed Patterns We Follow

### 1. Test Isolation

- Each test is independent and can run in any order
- `testExecutionOrdering = "random"` catches hidden dependencies
- No shared mutable state between tests

### 2. Memory Leak Detection

All tests include `trackForMemoryLeaks()`:

```swift
func test_something() async {
    let sut = makeSUT()
    trackForMemoryLeaks(sut)

    // ... test logic
}
```

### 3. Test Helpers for Clarity

- `makeSUT()`: Factory method for system under test
- Custom assertions for better error messages
- Shared test helpers for common operations

### 4. Integration Test Patterns

```swift
func test_loadVideo_deliversItemsSavedOnASeparateInstance() async throws {
    let loaderToPerformSave = try makeVideoLoader()
    let loaderToPerformLoad = try makeVideoLoader()
    let videos = [makeVideo(), makeVideo()]

    try await loaderToPerformSave.save(videos)

    let loadedVideos = try await loaderToPerformLoad.load()
    XCTAssertEqual(loadedVideos, videos)
}
```

**Key Points**:
- Tests real persistence with separate instances
- Verifies data survives across app lifecycle
- Uses test-specific store URLs for isolation

### 5. E2E Test Patterns

```swift
func test_endToEndTestServerGETVideosResult_matchesFixedTestAccountData() async {
    switch await getVideosResult() {
    case let .success(videos)?:
        XCTAssertEqual(videos.count, 5)
        XCTAssertEqual(videos[0], expectedVideo(at: 0))
        // ... validate all fields
    case let .failure(error)?:
        XCTFail("Expected successful videos result, got \(error) instead")
    default:
        XCTFail("Expected successful videos result, got no result instead")
    }
}
```

**Key Points**:
- Hits real API endpoint
- Uses ephemeral URLSession
- Validates exact contract with fixed test data
- Tracks memory leaks for client and loader

## Recommended Workflow

### During Development (Fast Feedback)

```bash
# Quick unit test run after changes
xcodebuild test -scheme StreamingCore -destination 'platform=iOS Simulator,name=iPhone 17'

# Or just iOS tests
xcodebuild test -scheme StreamingCoreiOS -destination 'platform=iOS Simulator,name=iPhone 17'
```

### Before Committing

```bash
# Run integration tests to verify persistence
xcodebuild test -scheme StreamingCoreCacheIntegrationTests -destination 'platform=iOS Simulator,name=iPhone 17'
```

### Before Pushing / In CI Pipeline

```bash
# Run full test suite with coverage
xcodebuild test -scheme CI_iOS \
    -destination 'platform=iOS Simulator,name=iPhone 17' \
    -enableCodeCoverage YES \
    -resultBundlePath ./TestResults.xcresult
```

### Before Releases

```bash
# Run E2E tests to validate real API
xcodebuild test -scheme StreamingCoreAPIEndToEndTests -destination 'platform=iOS Simulator,name=iPhone 17'

# Then run full CI suite
xcodebuild test -scheme CI_iOS -destination 'platform=iOS Simulator,name=iPhone 17'
```

## CI/CD Integration

### GitHub Actions Example

```yaml
name: CI

on: [push, pull_request]

jobs:
  test:
    runs-on: macos-latest

    steps:
      - uses: actions/checkout@v3

      - name: Run Tests
        run: |
          xcodebuild test \
            -project StreamingCore.xcodeproj \
            -scheme CI_iOS \
            -destination 'platform=iOS Simulator,name=iPhone 17' \
            -enableCodeCoverage YES \
            -resultBundlePath ./TestResults.xcresult

      - name: Generate Coverage Report
        run: |
          xcrun xccov view --report --json TestResults.xcresult > coverage.json
```

## Test Naming Conventions

We follow Essential Feed's naming pattern:

```swift
func test_<method>_<condition>_<expectedBehavior>() {
    // Example: test_load_deliversNoItemsOnEmptyCache
}
```

**Examples**:
- `test_init_doesNotLoadTableView`
- `test_load_deliversErrorOnClientError`
- `test_save_overridesPreviouslySavedVideos`
- `test_endToEndTestServerGETVideosResult_matchesFixedTestAccountData`

## Code Coverage Targets

The CI_iOS scheme is configured to generate coverage for:
- StreamingCore.framework
- StreamingCoreiOS.framework

**Target**: Aim for >80% code coverage, >90% for critical paths

**View Coverage**:
```bash
# After running CI_iOS scheme
xcrun xccov view --report TestResults.xcresult
```

## Debugging Tests

### CoreData Concurrency Issues

All schemes include `-com.apple.CoreData.ConcurrencyDebug 1` which will crash immediately on threading violations.

### Test Failures

1. Run specific test in isolation:
```bash
xcodebuild test -scheme StreamingCore \
    -destination 'platform=iOS Simulator,name=iPhone 17' \
    -only-testing:StreamingCoreTests/RemoteVideoLoaderTests/test_specific_test
```

2. Check test order dependencies:
```bash
# Tests should pass in any order
xcodebuild test -scheme CI_iOS \
    -destination 'platform=iOS Simulator,name=iPhone 17' \
    -test-iterations 5
```

### Memory Leaks

All tests use `trackForMemoryLeaks()`. If a leak is detected:

```
XCTAssertNil failed - Instance should have been deallocated. Potential memory leak.
```

Check for:
- Retain cycles (strong reference loops)
- Closures capturing `self` strongly
- Delegates not marked as `weak`

## Comparison with Essential Feed

| Aspect | Essential Feed | Our App |
|--------|---------------|---------|
| Unit Test Schemes | ✅ EssentialFeed, EssentialFeediOS | ✅ StreamingCore, StreamingCoreiOS |
| Integration Scheme | ✅ EssentialFeedCacheIntegrationTests | ✅ StreamingCoreCacheIntegrationTests |
| E2E Scheme | ✅ EssentialFeedAPIEndToEndTests | ✅ StreamingCoreAPIEndToEndTests |
| CI Scheme | ✅ CI_macOS, CI_iOS | ✅ CI_iOS |
| Code Coverage | ✅ Enabled in CI | ✅ Enabled in CI |
| Random Execution | ✅ Yes | ✅ Yes |
| Parallel Tests | ✅ Yes | ✅ Yes |
| CoreData Debug | ✅ Yes | ✅ Yes |

## Best Practices

1. **Write tests first (TDD)**: Red-Green-Refactor
2. **One assertion per test**: Makes failures clear
3. **Test behavior, not implementation**: Don't test private methods
4. **Use descriptive test names**: Test name should explain what it validates
5. **Keep tests fast**: Mock slow dependencies in unit tests
6. **Use real infrastructure in integration tests**: No mocks for CoreData
7. **Clean up after tests**: Delete test-specific files in tearDown
8. **Track memory leaks**: Always use `trackForMemoryLeaks()`

## Troubleshooting

### Tests are slow
- Run unit tests only: `xcodebuild test -scheme StreamingCore`
- Skip E2E tests during development
- Use CI_iOS scheme only before pushing

### Tests fail randomly
- Check for `testExecutionOrdering = "random"` - this exposes test dependencies
- Verify no shared mutable state
- Check for timing issues (use expectations properly)

### Integration tests fail
- Verify test-specific store URLs are unique
- Check CoreData model version
- Ensure proper cleanup in `tearDown`

### E2E tests fail
- Check network connectivity
- Verify GitHub Pages API is accessible
- Check if API contract changed
- Use `curl` to verify endpoint manually

## Future Enhancements

- [ ] UI Acceptance Tests (full app flow with stubs)
- [ ] Performance Tests (measure cache read/write speed)
- [ ] Snapshot Tests (UI visual regression testing)
- [ ] Contract Tests (validate API changes)
