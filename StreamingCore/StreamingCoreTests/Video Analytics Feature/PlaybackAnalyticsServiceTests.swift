//
//  PlaybackAnalyticsServiceTests.swift
//  StreamingCoreTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import XCTest
import StreamingCore

@MainActor
final class PlaybackAnalyticsServiceTests: XCTestCase {

    func test_startSession_createsSessionWithCorrectProperties() async {
        let (sut, _) = makeSUT()
        let videoID = UUID()
        let deviceInfo = makeDeviceInfo()

        let session = await sut.startSession(
            videoID: videoID,
            videoTitle: "Test Video",
            deviceInfo: deviceInfo,
            appVersion: "1.0.0"
        )

        XCTAssertEqual(session.videoID, videoID)
        XCTAssertEqual(session.videoTitle, "Test Video")
        XCTAssertEqual(session.deviceInfo, deviceInfo)
        XCTAssertEqual(session.appVersion, "1.0.0")
        XCTAssertNil(session.endTime)
    }

    func test_startSession_insertsSessionInStore() async throws {
        let (sut, store) = makeSUT()
        let videoID = UUID()

        let session = await sut.startSession(
            videoID: videoID,
            videoTitle: "Test Video",
            deviceInfo: makeDeviceInfo(),
            appVersion: "1.0.0"
        )

        let storedSessions = try await store.retrieveAllSessions()
        XCTAssertEqual(storedSessions.count, 1)
        XCTAssertEqual(storedSessions.first?.id, session.id)
    }

    func test_log_insertsEventInStore() async throws {
        let (sut, store) = makeSUT()
        let session = await sut.startSession(
            videoID: UUID(),
            videoTitle: "Test Video",
            deviceInfo: makeDeviceInfo(),
            appVersion: "1.0.0"
        )

        await sut.log(.play, position: 0)

        let result = try await store.retrieve(sessionID: session.id)
        XCTAssertEqual(result?.events.count, 1)
        XCTAssertEqual(result?.events.first?.eventType, "play")
    }

    func test_log_doesNothingWithoutActiveSession() async throws {
        let (sut, store) = makeSUT()

        await sut.log(.play, position: 0)

        let sessions = try await store.retrieveAllSessions()
        XCTAssertTrue(sessions.isEmpty)
    }

    func test_log_recordsMultipleEvents() async throws {
        let (sut, store) = makeSUT()
        let session = await sut.startSession(
            videoID: UUID(),
            videoTitle: "Test Video",
            deviceInfo: makeDeviceInfo(),
            appVersion: "1.0.0"
        )

        await sut.log(.play, position: 0)
        await sut.log(.pause, position: 30.0)
        await sut.log(.seek(from: 30.0, to: 60.0), position: 60.0)

        let result = try await store.retrieve(sessionID: session.id)
        XCTAssertEqual(result?.events.count, 3)
    }

    func test_endSession_logsCompletedEventAndUpdatesEndTime() async throws {
        let (sut, store) = makeSUT()
        let session = await sut.startSession(
            videoID: UUID(),
            videoTitle: "Test Video",
            deviceInfo: makeDeviceInfo(),
            appVersion: "1.0.0"
        )

        await sut.endSession(watchedDuration: 100.0, completed: true)

        let result = try await store.retrieve(sessionID: session.id)
        XCTAssertNotNil(result?.session.endTime)
        XCTAssertTrue(result?.events.contains { $0.eventType == "videoCompleted" } ?? false)
    }

    func test_endSession_logsAbandonedEventWhenNotCompleted() async throws {
        let (sut, store) = makeSUT()
        let session = await sut.startSession(
            videoID: UUID(),
            videoTitle: "Test Video",
            deviceInfo: makeDeviceInfo(),
            appVersion: "1.0.0"
        )

        await sut.endSession(watchedDuration: 50.0, completed: false)

        let result = try await store.retrieve(sessionID: session.id)
        XCTAssertTrue(result?.events.contains { $0.eventType == "videoAbandoned" } ?? false)
    }

    func test_endSession_clearsCurrentSession() async throws {
        let (sut, store) = makeSUT()
        _ = await sut.startSession(
            videoID: UUID(),
            videoTitle: "Test Video",
            deviceInfo: makeDeviceInfo(),
            appVersion: "1.0.0"
        )

        await sut.endSession(watchedDuration: 100.0, completed: true)
        await sut.log(.play, position: 0) // Should not log anything

        let sessions = try await store.retrieveAllSessions()
        let result = try await store.retrieve(sessionID: sessions.first!.id)
        // Should only have the videoCompleted event, not the play event
        XCTAssertEqual(result?.events.count, 1)
    }

    func test_trackVideoLoadStarted_startsPerformanceTracking() async {
        let (sut, _) = makeSUT()
        _ = await sut.startSession(
            videoID: UUID(),
            videoTitle: "Test Video",
            deviceInfo: makeDeviceInfo(),
            appVersion: "1.0.0"
        )

        await sut.trackVideoLoadStarted()
        await sut.trackFirstFrameRendered()

        let metrics = await sut.getCurrentPerformanceMetrics(watchDuration: 60.0)
        XCTAssertNotNil(metrics?.timeToFirstFrame)
    }

    func test_trackBuffering_tracksBufferingEvents() async {
        let (sut, _) = makeSUT()
        _ = await sut.startSession(
            videoID: UUID(),
            videoTitle: "Test Video",
            deviceInfo: makeDeviceInfo(),
            appVersion: "1.0.0"
        )

        await sut.trackBufferingStarted()
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        await sut.trackBufferingEnded()

        let metrics = await sut.getCurrentPerformanceMetrics(watchDuration: 60.0)
        XCTAssertEqual(metrics?.bufferingEvents, 1)
        XCTAssertGreaterThan(metrics?.totalBufferingDuration ?? 0, 0)
    }

    func test_getCurrentPerformanceMetrics_returnsNilWithoutSession() async {
        let (sut, _) = makeSUT()

        let metrics = await sut.getCurrentPerformanceMetrics(watchDuration: 60.0)

        XCTAssertNil(metrics)
    }

    func test_startSession_usesInjectedUUID() async {
        let fixedUUID = UUID()
        let (sut, _) = makeSUT(uuidGenerator: { fixedUUID })

        let session = await sut.startSession(
            videoID: UUID(),
            videoTitle: "Test Video",
            deviceInfo: makeDeviceInfo(),
            appVersion: "1.0.0"
        )

        XCTAssertEqual(session.id, fixedUUID)
    }

    func test_startSession_usesInjectedDate() async {
        let fixedDate = Date(timeIntervalSince1970: 1000)
        let (sut, _) = makeSUT(currentDate: { fixedDate })

        let session = await sut.startSession(
            videoID: UUID(),
            videoTitle: "Test Video",
            deviceInfo: makeDeviceInfo(),
            appVersion: "1.0.0"
        )

        XCTAssertEqual(session.startTime, fixedDate)
    }

    // MARK: - Helpers

    private func makeSUT(
        currentDate: @escaping @Sendable () -> Date = { Date() },
        uuidGenerator: @escaping @Sendable () -> UUID = { UUID() },
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: PlaybackAnalyticsService, store: InMemoryAnalyticsStore) {
        let store = InMemoryAnalyticsStore()
        let sut = PlaybackAnalyticsService(
            store: store,
            currentDate: currentDate,
            uuidGenerator: uuidGenerator
        )
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, store)
    }

    private func makeDeviceInfo() -> DeviceInfo {
        DeviceInfo(model: "iPhone", osVersion: "17.0", networkType: "WiFi")
    }
}
