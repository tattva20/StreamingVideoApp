import Foundation

public protocol VideoImageDataCache {
    func save(_ data: Data, for url: URL) throws
}
