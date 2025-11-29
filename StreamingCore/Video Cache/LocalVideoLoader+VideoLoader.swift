import Foundation

extension LocalVideoLoader {
    private struct LoadVideoTask: Sendable {
        let loader: LocalVideoLoader

        func callAsFunction() throws -> [Video] {
            try loader.load()
        }
    }
}

extension LocalVideoLoader: VideoLoader {
    public func load() async throws -> [Video] {
        try LoadVideoTask(loader: self)()
    }
}
