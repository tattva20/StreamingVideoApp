import Foundation

public protocol VideoCache {
    func save(_ videos: [Video]) throws
}
