//
//  Video.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas all rights reserved.
//
import Foundation

public struct Video: Hashable, Sendable {
    public let id: UUID
    public let title: String
    public let description: String?
    public let url: URL
    public let thumbnailURL: URL
    public let duration: TimeInterval

    public init(id: UUID,
                title: String,
                description: String? = nil,
                url: URL,
                thumbnailURL: URL,
                duration: TimeInterval) {
        self.id = id
        self.title = title
        self.description = description
        self.url = url
        self.thumbnailURL = thumbnailURL
        self.duration = duration
    }
}
