# Video Feed Feature

The Video Feed feature provides a paginated, cacheable list of videos with pull-to-refresh, infinite scroll, and offline support.

---

## Overview

```
┌─────────────────────────────────────────────────────────────┐
│                      Video Feed                              │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────┐    │
│  │  🎬 Video Thumbnail          │  Title              │    │
│  │                              │  Description...     │    │
│  │                              │  Duration: 2:34     │    │
│  └─────────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  🎬 Video Thumbnail          │  Title              │    │
│  │                              │  Description...     │    │
│  │                              │  Duration: 5:12     │    │
│  └─────────────────────────────────────────────────────┘    │
│                        ...                                   │
│  ┌─────────────────────────────────────────────────────┐    │
│  │              Loading more...                         │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

---

## Features

- **Paginated Loading** - Load videos in batches with cursor-based pagination
- **Pull-to-Refresh** - Refresh the feed by pulling down
- **Infinite Scroll** - Automatically load more when reaching the end
- **Lazy Image Loading** - Thumbnails load as cells become visible
- **Offline Support** - Cached videos available without network
- **Error Handling** - Retry mechanism for failed loads

---

## Architecture

### Domain Model

**File:** `StreamingCore/StreamingCore/Video Feature/Video.swift`

```swift
public struct Video: Hashable, Sendable {
    public let id: UUID
    public let title: String
    public let description: String
    public let url: URL
    public let thumbnailURL: URL
    public let duration: TimeInterval
}
```

### API Layer

**File:** `StreamingCore/StreamingCore/Video API/VideoEndpoint.swift`

```swift
public enum VideoEndpoint {
    case get(after: Video? = nil)

    public func url(baseURL: URL) -> URL {
        switch self {
        case let .get(video):
            var components = URLComponents(url: baseURL.appendingPathComponent("/v1/videos"), resolvingAgainstBaseURL: false)!
            components.queryItems = [URLQueryItem(name: "limit", value: "10")]
            if let video {
                components.queryItems?.append(URLQueryItem(name: "after_id", value: video.id.uuidString))
            }
            return components.url!
        }
    }
}
```

### Remote Loading

**File:** `StreamingCore/StreamingCore/Video API/RemoteVideoLoader.swift`

```swift
public final class RemoteVideoLoader: VideoLoader {
    private let client: HTTPClient
    private let url: URL

    public func load() -> AnyPublisher<[Video], Error> {
        client.getPublisher(url: url)
            .tryMap { data, response in
                try VideoItemsMapper.map(data, from: response)
            }
            .eraseToAnyPublisher()
    }
}
```

### Data Mapping

**File:** `StreamingCore/StreamingCore/Video API/VideoItemsMapper.swift`

```swift
public final class VideoItemsMapper {
    public static func map(_ data: Data, from response: HTTPURLResponse) throws -> [Video] {
        guard response.isOK,
              let root = try? JSONDecoder().decode(Root.self, from: data) else {
            throw Error.invalidData
        }
        return root.items
    }
}
```

---

## Pagination

### Paginated Wrapper

**File:** `StreamingCore/StreamingCore/Shared API/Paginated.swift`

```swift
public struct Paginated<Item> {
    public let items: [Item]
    public let loadMore: ((@escaping LoadMoreCompletion) -> Void)?

    public typealias LoadMoreCompletion = (Result<Self, Error>) -> Void
}
```

### Load More Flow

```
User scrolls to bottom
        │
        ▼
┌───────────────────┐
│ LoadMoreCell      │
│ appears on screen │
└───────────────────┘
        │
        ▼
┌───────────────────┐
│ loadMore closure  │
│ is called         │
└───────────────────┘
        │
        ▼
┌───────────────────┐
│ Fetch next page   │
│ with after_id     │
└───────────────────┘
        │
        ▼
┌───────────────────┐
│ Append new items  │
│ to existing list  │
└───────────────────┘
```

---

## UI Components

### List View Controller

**File:** `StreamingCoreiOS/Shared UI/Controllers/ListViewController.swift`

Generic list controller handling:
- Table view setup
- Pull-to-refresh
- Error display
- Loading states

### Video Cell

**File:** `StreamingCoreiOS/Video UI/Views/VideoCell.swift`

Displays:
- Thumbnail image (lazy loaded)
- Video title
- Description
- Duration

### Video Cell Controller

**File:** `StreamingCoreiOS/Video UI/Controllers/VideoCellController.swift`

```swift
public final class VideoCellController: NSObject {
    private let viewModel: VideoViewModel
    private let imageLoader: (URL) -> VideoImageDataLoader.Publisher
    private let selection: () -> Void

    public func view(in tableView: UITableView) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "VideoCell") as! VideoCell
        cell.titleLabel.text = viewModel.title
        cell.descriptionLabel.text = viewModel.description
        loadImage()
        return cell
    }
}
```

### Load More Cell

**File:** `StreamingCoreiOS/Video UI/Views/LoadMoreCell.swift`

Triggers pagination when visible.

---

## Caching Strategy

### Cache-First Loading

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│    Remote    │────▶│    Cache     │────▶│   Display    │
│    Loader    │     │   Decorator  │     │              │
└──────────────┘     └──────────────┘     └──────────────┘
        │                   │
        │                   ▼
        │            ┌──────────────┐
        │            │  Save to     │
        │            │  Local Store │
        │            └──────────────┘
        │
        ▼ (on failure)
┌──────────────┐
│   Fallback   │
│   to Cache   │
└──────────────┘
```

### Video Loader Cache Decorator

```swift
public final class VideoLoaderCacheDecorator: VideoLoader {
    private let decoratee: VideoLoader
    private let cache: VideoCache

    public func load() async throws -> [Video] {
        let videos = try await decoratee.load()
        try cache.save(videos)  // Cache on success
        return videos
    }
}
```

### Fallback Composite

```swift
public final class VideoLoaderWithFallbackComposite: VideoLoader {
    private let primary: VideoLoader
    private let fallback: VideoLoader

    public func load() async throws -> [Video] {
        do {
            return try await primary.load()
        } catch {
            return try await fallback.load()  // Use cache on failure
        }
    }
}
```

---

## Composition

**File:** `StreamingVideoApp/VideosUIComposer.swift`

```swift
public enum VideosUIComposer {
    public static func videosComposedWith(
        videoLoader: @escaping () -> AnyPublisher<Paginated<Video>, Error>,
        imageLoader: @escaping (URL) -> VideoImageDataLoader.Publisher,
        selection: @escaping (Video) -> Void
    ) -> ListViewController {
        let controller = ListViewController()

        let presentationAdapter = LoadResourcePresentationAdapter(loader: videoLoader)
        controller.onRefresh = presentationAdapter.loadResource

        presentationAdapter.presenter = LoadResourcePresenter(
            resourceView: VideosViewAdapter(
                controller: controller,
                imageLoader: imageLoader,
                selection: selection
            ),
            loadingView: WeakRefVirtualProxy(controller),
            errorView: WeakRefVirtualProxy(controller)
        )

        return controller
    }
}
```

---

## API Response Format

```json
{
  "videos": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "title": "Big Buck Bunny",
      "description": "A large rabbit deals with three bullying rodents.",
      "video_url": "https://example.com/video.mp4",
      "thumbnail_url": "https://example.com/thumbnail.jpg",
      "duration": 596
    }
  ]
}
```

---

## Error Handling

### Error Types

```swift
public enum RemoteVideoLoader.Error: Swift.Error {
    case connectivity  // Network failure
    case invalidData   // Parsing failure
}
```

### User Experience

| Error | UI Response |
|-------|-------------|
| Network failure | Show error view with retry button |
| Invalid data | Show error view with retry button |
| Empty response | Show empty state |

---

## Testing

### Unit Tests

```swift
func test_load_deliversVideosOn200HTTPResponseWithJSONItems() async throws {
    let (sut, client) = makeSUT()
    let video = makeVideo()

    client.complete(with: makeItemsJSON([video.json]))

    let result = try await sut.load()
    XCTAssertEqual(result, [video.model])
}

func test_load_deliversErrorOnClientError() async {
    let (sut, client) = makeSUT()

    client.complete(with: anyNSError())

    await assertThrows(try await sut.load())
}
```

### Integration Tests

```swift
func test_videosView_loadsAndDisplaysVideos() {
    let (sut, loader) = makeSUT()

    sut.simulateAppearance()
    loader.complete(with: [video1, video2])

    XCTAssertEqual(sut.numberOfRenderedVideos, 2)
}
```

---

## Related Documentation

- [Thumbnail Loading](THUMBNAIL-LOADING.md) - Image caching
- [Offline Support](OFFLINE-SUPPORT.md) - Cache strategies
- [Architecture](../ARCHITECTURE.md) - Layer boundaries
