//
//  ManagedVideo.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas all rights reserved.
//
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
    @NSManaged var data: Data?
    @NSManaged var cache: ManagedCache
}

extension ManagedVideo {
    static func data(with url: URL, in context: NSManagedObjectContext) throws -> Data? {
        if let data = context.userInfo[url] as? Data { return data }

        return try first(with: url, in: context)?.data
    }

    static func first(with url: URL, in context: NSManagedObjectContext) throws -> ManagedVideo? {
        let request = NSFetchRequest<ManagedVideo>(entityName: entity().name!)
        request.predicate = NSPredicate(format: "%K = %@", argumentArray: [#keyPath(ManagedVideo.thumbnailURL), url])
        request.returnsObjectsAsFaults = false
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    static func videos(from localVideos: [LocalVideo], in context: NSManagedObjectContext) -> NSOrderedSet {
        let videos = NSOrderedSet(array: localVideos.map { local in
            let managed = ManagedVideo(context: context)
            managed.id = local.id
            managed.title = local.title
            managed.videoDescription = local.description
            managed.url = local.url
            managed.thumbnailURL = local.thumbnailURL
            managed.duration = local.duration
            managed.data = context.userInfo[local.thumbnailURL] as? Data
            return managed
        })
        context.userInfo.removeAllObjects()
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

    override func prepareForDeletion() {
        super.prepareForDeletion()

        managedObjectContext?.userInfo[thumbnailURL] = data
    }
}
