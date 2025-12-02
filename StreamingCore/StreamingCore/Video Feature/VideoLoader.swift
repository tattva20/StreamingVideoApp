import Foundation
import Combine

@MainActor
public protocol VideoLoader {
    func load() -> AnyPublisher<[Video], Error>
}
