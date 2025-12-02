//
//  InMemoryAnalyticsStoreTests.swift
//  StreamingCoreTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import XCTest
import StreamingCore

@MainActor
final class InMemoryAnalyticsStoreTests: XCTestCase {

    func test_retrieveAllSessions_deliversEmptyOnEmptyCache() async throws {
        let sut = makeSUT()

        let sessions = try await sut.retrieveAllSessions()

        XCTAssertTrue(sessions.isEmpty)
    }

    func test_retrieve_deliversNilOnEmptyCache() async throws {
        let sut = makeSUT()

        let result = try await sut.retrieve(sessionID: UUID())

        XCTAssertNil(result)
    }

    func test_insert_deliversInsertedSessionOnRetrieval() async throws {
        let sut = makeSUT()
        let session = makeLocalSession()

        try await sut.insert(session)
        let result = try await sut.retrieve(sessionID: session.id)

        XCTAssertEqual(result?.session, session)
        XCTAssertTrue(result?.events.isEmpty ?? false)
    }

    func test_insert_deliversMultipleSessionsOnRetrieveAll() async throws {
        let sut = makeSUT()
        let session1 = makeLocalSession()
        let session2 = makeLocalSession()

        try await sut.insert(session1)
        try await sut.insert(session2)
        let sessions = try await sut.retrieveAllSessions()

        XCTAssertEqual(sessions.count, 2)
        XCTAssertTrue(sessions.contains(session1))
        XCTAssertTrue(sessions.contains(session2))
    }

    func test_insertEvent_deliversEventOnSessionRetrieval() async throws {
        let sut = makeSUT()
        let session = makeLocalSession()
        let event = makeLocalEvent(sessionID: session.id)

        try await sut.insert(session)
        try await sut.insertEvent(event)
        let result = try await sut.retrieve(sessionID: session.id)

        XCTAssertEqual(result?.events.count, 1)
        XCTAssertEqual(result?.events.first, event)
    }

    func test_insertEvent_deliversMultipleEventsInOrder() async throws {
        let sut = makeSUT()
        let session = makeLocalSession()
        let event1 = makeLocalEvent(sessionID: session.id)
        let event2 = makeLocalEvent(sessionID: session.id)
        let event3 = makeLocalEvent(sessionID: session.id)

        try await sut.insert(session)
        try await sut.insertEvent(event1)
        try await sut.insertEvent(event2)
        try await sut.insertEvent(event3)
        let result = try await sut.retrieve(sessionID: session.id)

        XCTAssertEqual(result?.events, [event1, event2, event3])
    }

    func test_updateSession_updatesExistingSession() async throws {
        let sut = makeSUT()
        let sessionID = UUID()
        let originalSession = makeLocalSession(id: sessionID, endTime: nil)
        let endTime = Date()
        let updatedSession = makeLocalSession(id: sessionID, endTime: endTime)

        try await sut.insert(originalSession)
        try await sut.updateSession(updatedSession)
        let result = try await sut.retrieve(sessionID: sessionID)

        XCTAssertEqual(result?.session.endTime, endTime)
    }

    func test_updateSession_preservesExistingEvents() async throws {
        let sut = makeSUT()
        let sessionID = UUID()
        let originalSession = makeLocalSession(id: sessionID)
        let event = makeLocalEvent(sessionID: sessionID)
        let updatedSession = makeLocalSession(id: sessionID, endTime: Date())

        try await sut.insert(originalSession)
        try await sut.insertEvent(event)
        try await sut.updateSession(updatedSession)
        let result = try await sut.retrieve(sessionID: sessionID)

        XCTAssertEqual(result?.events.count, 1)
        XCTAssertEqual(result?.events.first, event)
    }

    func test_deleteSession_removesSessionFromCache() async throws {
        let sut = makeSUT()
        let session = makeLocalSession()

        try await sut.insert(session)
        try await sut.deleteSession(session.id)
        let result = try await sut.retrieve(sessionID: session.id)

        XCTAssertNil(result)
    }

    func test_deleteSession_removesAssociatedEvents() async throws {
        let sut = makeSUT()
        let session = makeLocalSession()
        let event = makeLocalEvent(sessionID: session.id)

        try await sut.insert(session)
        try await sut.insertEvent(event)
        try await sut.deleteSession(session.id)
        let result = try await sut.retrieve(sessionID: session.id)

        XCTAssertNil(result)
    }

    func test_deleteSession_doesNotAffectOtherSessions() async throws {
        let sut = makeSUT()
        let session1 = makeLocalSession()
        let session2 = makeLocalSession()

        try await sut.insert(session1)
        try await sut.insert(session2)
        try await sut.deleteSession(session1.id)
        let sessions = try await sut.retrieveAllSessions()

        XCTAssertEqual(sessions.count, 1)
        XCTAssertEqual(sessions.first, session2)
    }

    func test_deleteAllSessions_removesAllSessionsFromCache() async throws {
        let sut = makeSUT()
        let session1 = makeLocalSession()
        let session2 = makeLocalSession()

        try await sut.insert(session1)
        try await sut.insert(session2)
        try await sut.deleteAllSessions()
        let sessions = try await sut.retrieveAllSessions()

        XCTAssertTrue(sessions.isEmpty)
    }

    func test_deleteAllSessions_removesAllEventsFromCache() async throws {
        let sut = makeSUT()
        let session = makeLocalSession()
        let event = makeLocalEvent(sessionID: session.id)

        try await sut.insert(session)
        try await sut.insertEvent(event)
        try await sut.deleteAllSessions()
        let result = try await sut.retrieve(sessionID: session.id)

        XCTAssertNil(result)
    }

    func test_concurrentInserts_areThreadSafe() async throws {
        let sut = makeSUT()
        let sessions = (0..<100).map { _ in makeLocalSession() }

        await withTaskGroup(of: Void.self) { group in
            for session in sessions {
                group.addTask {
                    try? await sut.insert(session)
                }
            }
        }

        let retrievedSessions = try await sut.retrieveAllSessions()
        XCTAssertEqual(retrievedSessions.count, 100)
    }

    func test_concurrentEventInserts_areThreadSafe() async throws {
        let sut = makeSUT()
        let session = makeLocalSession()
        try await sut.insert(session)

        let events = (0..<100).map { _ in makeLocalEvent(sessionID: session.id) }

        await withTaskGroup(of: Void.self) { group in
            for event in events {
                group.addTask {
                    try? await sut.insertEvent(event)
                }
            }
        }

        let result = try await sut.retrieve(sessionID: session.id)
        XCTAssertEqual(result?.events.count, 100)
    }

    // MARK: - Helpers

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> InMemoryAnalyticsStore {
        let sut = InMemoryAnalyticsStore()
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }

    private func makeLocalSession(
        id: UUID = UUID(),
        endTime: Date? = nil
    ) -> LocalPlaybackSession {
        LocalPlaybackSession(
            id: id,
            videoID: UUID(),
            videoTitle: "Test Video",
            startTime: Date(),
            endTime: endTime,
            deviceModel: "iPhone",
            osVersion: "17.0",
            networkType: "WiFi",
            appVersion: "1.0.0"
        )
    }

    private func makeLocalEvent(sessionID: UUID) -> LocalPlaybackEvent {
        LocalPlaybackEvent(
            id: UUID(),
            sessionID: sessionID,
            videoID: UUID(),
            eventType: "play",
            eventData: nil,
            timestamp: Date(),
            currentPosition: 0
        )
    }

}
