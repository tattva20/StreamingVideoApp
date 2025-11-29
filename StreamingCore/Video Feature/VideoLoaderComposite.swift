import Foundation

public final class VideoLoaderComposite: VideoLoader {
    private let primary: VideoLoader
    private let fallback: VideoLoader

    public init(primary: VideoLoader, fallback: VideoLoader) {
        self.primary = primary
        self.fallback = fallback
    }

    public func load() async throws -> [Video] {
        do {
            return try await primary.load()
        } catch {
            return try await fallback.load()
        }
    }
}
