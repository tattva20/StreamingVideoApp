# Thumbnail Loading Feature

The Thumbnail Loading feature provides lazy image loading with caching for video thumbnails in the feed.

---

## Overview

```
┌─────────────────────────────────────────────────────────────┐
│  ┌───────────────┐                                          │
│  │ ░░░░░░░░░░░░░ │  Video Title                            │
│  │ ░ Shimmer ░░░ │  Description...                         │
│  │ ░░░░░░░░░░░░░ │                          Loading...     │
│  └───────────────┘                                          │
├─────────────────────────────────────────────────────────────┤
│  ┌───────────────┐                                          │
│  │               │  Video Title                             │
│  │  🖼️ Image    │  Description...                          │
│  │               │                              ✓ Loaded    │
│  └───────────────┘                                          │
└─────────────────────────────────────────────────────────────┘
```

---

## Features

- **Lazy Loading** - Images load as cells become visible
- **Memory Cache** - Fast access to recently loaded images
- **Disk Cache** - Persistent storage for offline access
- **Shimmer Effect** - Loading placeholder animation
- **Fade Animation** - Smooth appearance when loaded
- **Request Cancellation** - Cancel loads for scrolled-past cells
- **Error Handling** - Retry mechanism for failed loads

---

## Architecture

### Protocol

**File:** `StreamingCore/StreamingCore/Video Image Feature/VideoImageDataLoader.swift`

```swift
public protocol VideoImageDataLoader {
    func loadImageData(from url: URL) async throws -> Data
}

public extension VideoImageDataLoader {
    typealias Publisher = AnyPublisher<Data, Error>
}
```

### Cache Protocol

**File:** `StreamingCore/StreamingCore/Video Image Feature/VideoImageDataCache.swift`

```swift
public protocol VideoImageDataCache {
    func save(_ data: Data, for url: URL) throws
}
```

---

## Remote Loading

### RemoteVideoImageDataLoader

```swift
public final class RemoteVideoImageDataLoader: VideoImageDataLoader {
    private let client: HTTPClient

    public func loadImageData(from url: URL) async throws -> Data {
        let (data, response) = try await client.get(from: url)
        return try VideoImageDataMapper.map(data, from: response)
    }
}
```

### Data Validation

**File:** `StreamingCore/StreamingCore/Video API/VideoImageDataMapper.swift`

```swift
public final class VideoImageDataMapper {
    public static func map(_ data: Data, from response: HTTPURLResponse) throws -> Data {
        guard response.isOK, !data.isEmpty else {
            throw Error.invalidData
        }
        return data
    }
}
```

---

## Caching Layer

### Local Image Data Loader

**File:** `StreamingCore/StreamingCore/Video Cache/LocalVideoImageDataLoader.swift`

```swift
public final class LocalVideoImageDataLoader {
    private let store: VideoImageDataStore

    public func loadImageData(from url: URL) throws -> Data {
        guard let data = try store.retrieve(dataForURL: url) else {
            throw Error.notFound
        }
        return data
    }

    public func save(_ data: Data, for url: URL) throws {
        try store.insert(data, for: url)
    }
}
```

### FileSystem Store

**File:** `StreamingCore/StreamingCore/Video Cache/Infrastructure/FileSystem/FileSystemVideoImageDataStore.swift`

```swift
public final class FileSystemVideoImageDataStore: VideoImageDataStore {
    private let storeURL: URL

    public func insert(_ data: Data, for url: URL) throws {
        let fileURL = cacheURL(for: url)
        try data.write(to: fileURL)
    }

    public func retrieve(dataForURL url: URL) throws -> Data? {
        let fileURL = cacheURL(for: url)
        return try? Data(contentsOf: fileURL)
    }

    private func cacheURL(for url: URL) -> URL {
        let filename = url.absoluteString.data(using: .utf8)!.base64EncodedString()
        return storeURL.appendingPathComponent(filename)
    }
}
```

---

## Cache Decorator

### VideoImageDataLoaderCacheDecorator

```swift
public final class VideoImageDataLoaderCacheDecorator: VideoImageDataLoader {
    private let decoratee: VideoImageDataLoader
    private let cache: VideoImageDataCache

    public func loadImageData(from url: URL) async throws -> Data {
        let data = try await decoratee.loadImageData(from: url)
        try? cache.save(data, for: url)  // Cache on success
        return data
    }
}
```

### Fallback Composite

```swift
public final class VideoImageDataLoaderWithFallbackComposite: VideoImageDataLoader {
    private let primary: VideoImageDataLoader
    private let fallback: VideoImageDataLoader

    public func loadImageData(from url: URL) async throws -> Data {
        do {
            return try await primary.loadImageData(from: url)
        } catch {
            return try await fallback.loadImageData(from: url)
        }
    }
}
```

---

## Loading Flow

```
Cell becomes visible
        │
        ▼
┌───────────────────┐
│ Check memory      │
│ cache             │────────────────┐
└───────────────────┘                │ hit
        │ miss                       │
        ▼                            ▼
┌───────────────────┐         ┌─────────────┐
│ Check disk        │         │ Display     │
│ cache             │────────▶│ image       │
└───────────────────┘   hit   └─────────────┘
        │ miss                       ▲
        ▼                            │
┌───────────────────┐                │
│ Fetch from        │                │
│ network           │────────────────┘
└───────────────────┘
        │
        ▼
┌───────────────────┐
│ Save to disk      │
│ cache             │
└───────────────────┘
```

---

## UI Integration

### VideoCellController

```swift
public final class VideoCellController: NSObject {
    private let imageLoader: (URL) -> VideoImageDataLoader.Publisher
    private var cancellable: AnyCancellable?
    private var cell: VideoCell?

    func preload() {
        loadImage()
    }

    func cancelLoad() {
        cancellable?.cancel()
        cancellable = nil
    }

    private func loadImage() {
        cell?.thumbnailImageView.startShimmering()

        cancellable = imageLoader(viewModel.thumbnailURL)
            .dispatchOnMainThread()
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure = completion {
                        self?.cell?.thumbnailImageView.stopShimmering()
                    }
                },
                receiveValue: { [weak self] data in
                    self?.cell?.thumbnailImageView.stopShimmering()
                    self?.cell?.thumbnailImageView.setImageAnimated(UIImage(data: data))
                }
            )
    }
}
```

### UITableViewDataSourcePrefetching

```swift
extension ListViewController: UITableViewDataSourcePrefetching {
    public func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach { indexPath in
            cellController(at: indexPath)?.preload()
        }
    }

    public func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach { indexPath in
            cellController(at: indexPath)?.cancelLoad()
        }
    }
}
```

---

## Animations

### Shimmer Effect

**File:** `StreamingCoreiOS/Video UI/Views/Helpers/UIView+Shimmering.swift`

```swift
extension UIView {
    func startShimmering() {
        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor.systemGray5.cgColor,
            UIColor.systemGray4.cgColor,
            UIColor.systemGray5.cgColor
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)
        gradient.frame = bounds

        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = [-1.0, -0.5, 0.0]
        animation.toValue = [1.0, 1.5, 2.0]
        animation.duration = 1.5
        animation.repeatCount = .infinity

        gradient.add(animation, forKey: "shimmer")
        layer.addSublayer(gradient)
    }

    func stopShimmering() {
        layer.sublayers?.removeAll { $0.animation(forKey: "shimmer") != nil }
    }
}
```

### Fade-In Animation

**File:** `StreamingCoreiOS/Video UI/Views/Helpers/UIImageView+Animations.swift`

```swift
extension UIImageView {
    func setImageAnimated(_ image: UIImage?) {
        self.image = image

        guard image != nil else { return }

        alpha = 0
        UIView.animate(withDuration: 0.3) {
            self.alpha = 1
        }
    }
}
```

---

## Composition

```swift
// In SceneDelegate
func makeImageLoader() -> (URL) -> VideoImageDataLoader.Publisher {
    return { [httpClient, localImageLoader, imageCache] url in
        let remoteLoader = RemoteVideoImageDataLoader(client: httpClient)
        let cachedRemoteLoader = VideoImageDataLoaderCacheDecorator(
            decoratee: remoteLoader,
            cache: imageCache
        )
        let loaderWithFallback = VideoImageDataLoaderWithFallbackComposite(
            primary: cachedRemoteLoader,
            fallback: localImageLoader
        )

        return loaderWithFallback.loadPublisher(from: url)
    }
}
```

---

## Testing

### Remote Loader Tests

```swift
func test_loadImageData_deliversDataOn200Response() async throws {
    let (sut, client) = makeSUT()
    let imageData = anyImageData()

    client.complete(with: imageData)

    let result = try await sut.loadImageData(from: anyURL())
    XCTAssertEqual(result, imageData)
}
```

### Cache Tests

```swift
func test_load_deliversCachedDataOnCacheHit() async throws {
    let (sut, store) = makeSUT()
    let cachedData = anyImageData()
    store.stub(dataForURL: anyURL(), with: cachedData)

    let result = try await sut.loadImageData(from: anyURL())
    XCTAssertEqual(result, cachedData)
}
```

---

## Related Documentation

- [Video Feed](VIDEO-FEED.md) - Feed integration
- [Offline Support](OFFLINE-SUPPORT.md) - Cache strategies
- [Design Patterns](../DESIGN-PATTERNS.md) - Decorator pattern
