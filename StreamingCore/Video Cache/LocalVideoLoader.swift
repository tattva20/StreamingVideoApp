import Foundation

public final class LocalVideoLoader {
    private let store: VideoStore
    private let currentDate: () -> Date

    public init(store: VideoStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }

    public func load() throws -> [Video] {
        _ = try store.retrieve()
        return []
    }
}
