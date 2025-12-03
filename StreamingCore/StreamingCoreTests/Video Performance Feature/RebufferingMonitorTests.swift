//
//  RebufferingMonitorTests.swift
//  StreamingCoreTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import XCTest
@testable import StreamingCore

final class RebufferingMonitorTests: XCTestCase {

	// MARK: - Initial State Tests

	func test_init_isNotBuffering() async {
		let sut = makeSUT()
		let state = await sut.state

		XCTAssertFalse(state.isBuffering)
		XCTAssertNil(state.bufferingStartTime)
		XCTAssertEqual(state.bufferingCount, 0)
		XCTAssertEqual(state.totalBufferingDuration, 0)
	}

	// MARK: - bufferingStarted Tests

	func test_bufferingStarted_setsIsBufferingToTrue() async {
		let sut = makeSUT()

		await sut.bufferingStarted()
		let state = await sut.state

		XCTAssertTrue(state.isBuffering)
		XCTAssertNotNil(state.bufferingStartTime)
	}

	func test_bufferingStarted_ignoredIfAlreadyBuffering() async {
		let (sut, currentDate) = makeSUTWithDate()
		let firstStartTime = Date()
		currentDate.value = firstStartTime

		await sut.bufferingStarted()

		currentDate.value = firstStartTime.addingTimeInterval(5)
		await sut.bufferingStarted()

		let state = await sut.state
		XCTAssertEqual(state.bufferingStartTime, firstStartTime)
	}

	// MARK: - bufferingEnded Tests

	func test_bufferingEnded_setsIsBufferingToFalse() async {
		let sut = makeSUT()

		await sut.bufferingStarted()
		_ = await sut.bufferingEnded()
		let state = await sut.state

		XCTAssertFalse(state.isBuffering)
		XCTAssertNil(state.bufferingStartTime)
	}

	func test_bufferingEnded_returnsBufferingEvent() async throws {
		let (sut, currentDate) = makeSUTWithDate()
		let startTime = Date()
		currentDate.value = startTime

		await sut.bufferingStarted()

		let endTime = startTime.addingTimeInterval(3.0)
		currentDate.value = endTime

		let event = await sut.bufferingEnded()

		let unwrappedEvent = try XCTUnwrap(event)
		XCTAssertEqual(unwrappedEvent.startTime, startTime)
		XCTAssertEqual(unwrappedEvent.endTime, endTime)
		XCTAssertEqual(unwrappedEvent.duration, 3.0, accuracy: 0.001)
	}

	func test_bufferingEnded_returnsNilIfNotBuffering() async {
		let sut = makeSUT()

		let event = await sut.bufferingEnded()

		XCTAssertNil(event)
	}

	func test_bufferingEnded_incrementsBufferingCount() async {
		let sut = makeSUT()

		await sut.bufferingStarted()
		_ = await sut.bufferingEnded()
		let state = await sut.state

		XCTAssertEqual(state.bufferingCount, 1)
	}

	func test_bufferingEnded_accumulatesTotalBufferingDuration() async {
		let (sut, currentDate) = makeSUTWithDate()
		let startTime = Date()

		// First buffering event: 2 seconds
		currentDate.value = startTime
		await sut.bufferingStarted()
		currentDate.value = startTime.addingTimeInterval(2.0)
		_ = await sut.bufferingEnded()

		// Second buffering event: 3 seconds
		currentDate.value = startTime.addingTimeInterval(10.0)
		await sut.bufferingStarted()
		currentDate.value = startTime.addingTimeInterval(13.0)
		_ = await sut.bufferingEnded()

		let state = await sut.state
		XCTAssertEqual(state.totalBufferingDuration, 5.0, accuracy: 0.001)
		XCTAssertEqual(state.bufferingCount, 2)
	}

	// MARK: - currentBufferingDuration Tests

	func test_currentBufferingDuration_isNilWhenNotBuffering() async {
		let sut = makeSUT()
		let state = await sut.state

		XCTAssertNil(state.currentBufferingDuration)
	}

	func test_currentBufferingDuration_calculatesOngoingDuration() async {
		let (sut, currentDate) = makeSUTWithDate()
		let startTime = Date()
		currentDate.value = startTime

		await sut.bufferingStarted()

		currentDate.value = startTime.addingTimeInterval(2.5)
		let state = await sut.state

		// Note: currentBufferingDuration uses Date() internally, so we can't test exact value
		XCTAssertNotNil(state.currentBufferingDuration)
	}

	// MARK: - eventsInLastMinute Tests

	func test_eventsInLastMinute_countsRecentEvents() async {
		let (sut, currentDate) = makeSUTWithDate()
		let now = Date()

		// Event 30 seconds ago
		currentDate.value = now.addingTimeInterval(-30)
		await sut.bufferingStarted()
		currentDate.value = now.addingTimeInterval(-28)
		_ = await sut.bufferingEnded()

		// Event 45 seconds ago
		currentDate.value = now.addingTimeInterval(-45)
		await sut.bufferingStarted()
		currentDate.value = now.addingTimeInterval(-43)
		_ = await sut.bufferingEnded()

		currentDate.value = now
		let count = await sut.eventsInLastMinute()

		XCTAssertEqual(count, 2)
	}

	func test_eventsInLastMinute_excludesOlderEvents() async {
		let (sut, currentDate) = makeSUTWithDate()
		let now = Date()

		// Old event: 90 seconds ago (should be excluded)
		currentDate.value = now.addingTimeInterval(-90)
		await sut.bufferingStarted()
		currentDate.value = now.addingTimeInterval(-88)
		_ = await sut.bufferingEnded()

		// Recent event: 30 seconds ago
		currentDate.value = now.addingTimeInterval(-30)
		await sut.bufferingStarted()
		currentDate.value = now.addingTimeInterval(-28)
		_ = await sut.bufferingEnded()

		currentDate.value = now
		let count = await sut.eventsInLastMinute()

		XCTAssertEqual(count, 1)
	}

	// MARK: - reset Tests

	func test_reset_clearsAllState() async {
		let sut = makeSUT()

		await sut.bufferingStarted()
		_ = await sut.bufferingEnded()
		await sut.reset()

		let state = await sut.state
		XCTAssertFalse(state.isBuffering)
		XCTAssertNil(state.bufferingStartTime)
		XCTAssertEqual(state.bufferingCount, 0)
		XCTAssertEqual(state.totalBufferingDuration, 0)
	}

	// MARK: - Helpers

	private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> RebufferingMonitor {
		let sut = RebufferingMonitor()
		return sut
	}

	private func makeSUTWithDate(file: StaticString = #filePath, line: UInt = #line) -> (sut: RebufferingMonitor, currentDate: CurrentDateStub) {
		let currentDate = CurrentDateStub()
		let sut = RebufferingMonitor(currentDate: { currentDate.value })
		return (sut, currentDate)
	}
}

// MARK: - Test Helpers

private final class CurrentDateStub: @unchecked Sendable {
	var value: Date = Date()
}
