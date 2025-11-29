import CoreData
import Foundation

@objc(ManagedVideo)
final class ManagedVideo: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var title: String
    @NSManaged var videoDescription: String?
    @NSManaged var url: URL
    @NSManaged var thumbnailURL: URL
    @NSManaged var duration: TimeInterval
    @NSManaged var cache: ManagedCache
}

extension ManagedVideo {
    static func videos(from localVideos: [LocalVideo], in context: NSManagedObjectContext) -> NSOrderedSet {
        let videos = NSOrderedSet(array: localVideos.map { local in
            let managed = ManagedVideo(context: context)
            managed.id = local.id
            managed.title = local.title
            managed.videoDescription = local.description
            managed.url = local.url
            managed.thumbnailURL = local.thumbnailURL
            managed.duration = local.duration
            return managed
        })
        return videos
    }

    var local: LocalVideo {
        return LocalVideo(
            id: id,
            title: title,
            description: videoDescription,
            url: url,
            thumbnailURL: thumbnailURL,
            duration: duration
        )
    }
}
