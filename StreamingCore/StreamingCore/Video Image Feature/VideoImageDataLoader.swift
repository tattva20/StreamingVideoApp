import Foundation

public protocol VideoImageDataLoader {
	func loadImageData(from url: URL) throws -> Data
}
