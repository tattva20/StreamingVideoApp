import Foundation

public protocol VideoLoader {
    func load() async throws -> [Video]
}
