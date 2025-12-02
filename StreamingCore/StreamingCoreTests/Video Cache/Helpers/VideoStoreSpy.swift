//
//  VideoStoreSpy.swift
//  StreamingCoreTests
//
//  Copyright by Octavio Rojas all rights reserved.
//
import Foundation
import StreamingCore

class VideoStoreSpy: VideoStore {
    enum ReceivedMessage: Equatable {
        case deleteCachedVideos
        case insert([LocalVideo], Date)
        case retrieve
    }

    // ⭐ MESSAGE ACCUMULATION PATTERN (not counters!)
    private(set) var receivedMessages = [ReceivedMessage]()

    private var deletionResult: Result<Void, Error>?
    private var insertionResult: Result<Void, Error>?
    private var retrievalResult: Result<CachedVideos?, Error>?

    func deleteCachedVideos() throws {
        receivedMessages.append(.deleteCachedVideos)
        try deletionResult?.get()
    }

    func insert(_ videos: [LocalVideo], timestamp: Date) throws {
        receivedMessages.append(.insert(videos, timestamp))
        try insertionResult?.get()
    }

    func retrieve() throws -> CachedVideos? {
        receivedMessages.append(.retrieve)
        return try retrievalResult?.get()
    }

    // MARK: - Completion Helpers

    func completeDeletion(with error: Error) {
        deletionResult = .failure(error)
    }

    func completeDeletionSuccessfully() {
        deletionResult = .success(())
    }

    func completeInsertion(with error: Error) {
        insertionResult = .failure(error)
    }

    func completeInsertionSuccessfully() {
        insertionResult = .success(())
    }

    func completeRetrieval(with error: Error) {
        retrievalResult = .failure(error)
    }

    func completeRetrievalWithEmptyCache() {
        retrievalResult = .success(.none)
    }

    func completeRetrieval(with videos: [LocalVideo], timestamp: Date) {
        retrievalResult = .success((videos, timestamp))
    }
}
