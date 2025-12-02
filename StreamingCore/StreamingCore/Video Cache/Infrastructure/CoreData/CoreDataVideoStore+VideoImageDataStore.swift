import Foundation
import CoreData

extension CoreDataVideoStore: VideoImageDataStore {

    public func insert(_ data: Data, for url: URL) throws {
        try ManagedVideo.first(with: url, in: context)
            .map { $0.data = data }
            .map(context.save)
    }

    public func retrieve(dataForURL url: URL) throws -> Data? {
        try ManagedVideo.data(with: url, in: context)
    }

}
