import Foundation

public protocol VideoLoader {
    func load(completion: @escaping (Result<[Video], Error>) -> Void)
}
