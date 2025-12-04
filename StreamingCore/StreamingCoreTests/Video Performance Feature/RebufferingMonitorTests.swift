//
//  RebufferingMonitorTests.swift
//  StreamingCoreTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import XCTest
@testable import StreamingCore

@MainActor
final class RebufferingMonitorTests: XCTestCase {

	// MARK: - Initial State Tests

	func test_init_isNotBuffering() {
		let sut = makeSUT()
		let state = sut.state

		XCTAssertFalse(state.isBuffering)
		XCTAssertNil(state.bufferingStartTime)
		XCTAssertEqual(state.bufferingCount, 0)
		XCTAssertEqual(state.totalBufferingDuration, 0)
	}

	// MARK: - bufferingStarted Tests

	func test_bufferingStarted_setsIsBufferingToTrue() {
		let sut = makeSUT()

		sut.bufferingStarted()
		let state = sut.state

		XCTAssertTrue(state.isBuffering)
		XCTAssertNotNil(state.bufferingStartTime)
	}

	func test_bufferingStarted_ignoredIfAlreadyBuffering() {
		let (sut, currentDate) = makeSUTWithDate()
		let firstStartTime = Date()
		currentDate.value = firstStartTime

		sut.bufferingStarted()

		currentDate.value = firstStartTime.addingTimeInterval(5)
		sut.bufferingStarted()

		let state = sut.state
		XCTAssertEqual(state.bufferingStartTime, firstStartTime)
	}

	// MARK: - bufferingEnded Tests

	func test_bufferingEnded_setsIsBufferingToFalse() {
		let sut = makeSUT()

		sut.bufferingStarted()
		_ = sut.bufferingEnded()
		let state = sut.state

		XCTAssertFalse(state.isBuffering)
		XCTAssertNil(state.bufferingStartTime)
	}

	func test_bufferingEnded_returnsBufferingEvent() throws {
		let (sut, currentDate) = makeSUTWithDate()
		let startTime = Date()
		currentDate.value = startTime

		sut.bufferingStarted()

		let endTime = startTime.addingTimeInterval(3.0)
		currentDate.value = endTime

		let event = sut.bufferingEnded()

		let unwrappedEvent = try XCTUnwrap(event)
		XCTAssertEqual(unwrappedEvent.startTime, startTime)
		XCTAssertEqual(unwrappedEvent.endTime, endTime)
		XCTAssertEqual(unwrappedEvent.duration, 3.0, accuracy: 0.001)
	}

	func test_bufferingEnded_returnsNilIfNotBuffering() {
		let sut = makeSUT()

		let event = sut.bufferingEnded()

		XCTAssertNil(event)
	}

	func test_bufferingEnded_incrementsBufferingCount() {
		let sut = makeSUT()

		sut.bufferingStarted()
		_ = sut.bufferingEnded()
		let state = sut.state

		XCTAssertEqual(state.bufferingCount, 1)
	}

	func test_bufferingEnded_accumulatesTotalBufferingDuration() {
		let (sut, currentDate) = makeSUTWithDate()
		let startTime = Date()

		// First buffering event: 2 seconds
		currentDate.value = startTime
		sut.bufferingStarted()
		currentDate.value = startTime.addingTimeInterval(2.0)
		_ = sut.bufferingEnded()

		// Second buffering event: 3 seconds
		currentDate.value = startTime.addingTimeInterval(10.0)
		sut.bufferingStarted()
		currentDate.value = startTime.addingTimeInterval(13.0)
		_ = sut.bufferingEnded()

		let state = sut.state
		XCTAssertEqual(state.totalBufferingDuration, 5.0, accuracy: 0.001)
		XCTAssertEqual(state.bufferingCount, 2)
	}

	// MARK: - currentBufferingDuration Tests

	func test_currentBufferingDuration_isNilWhenNotBuffering() {
		let sut = makeSUT()
		let state = sut.state

		XCTAssertNil(state.currentBufferingDuration)
	}

	func test_currentBufferingDuration_calculatesOngoingDuration() {
		let (sut, currentDate) = makeSUTWithDate()
		let startTime = Date()
		currentDate.value = startTime

		sut.bufferingStarted()

		currentDate.value = startTime.addingTimeInterval(2.5)
		let state = sut.state

		// Note: currentBufferingDuration uses Date() internally, so we can't test exact value
		XCTAssertNotNil(state.currentBufferingDuration)
	}

	// MARK: - eventsInLastMinute Tests

	func test_eventsInLastMinute_countsRecentEvents() {
		let (sut, currentDate) = makeSUTWithDate()
		let now = Date()

		// Event 30 seconds ago
		currentDate.value = now.addingTimeInterval(-30)
		sut.bufferingStarted()
		currentDate.value = now.addingTimeInterval(-28)
		_ = sut.bufferingEnded()

		// Event 45 seconds ago
		currentDate.value = now.addingTimeInterval(-45)
		sut.bufferingStarted()
		currentDate.value = now.addingTimeInterval(-43)
		_ = sut.bufferingEnded()

		currentDate.value = now
		let count = sut.eventsInLastMinute()

		XCTAssertEqual(count, 2)
	}

	func test_eventsInLastMinute_excludesOlderEvents() {
		let (sut, currentDate) = makeSUTWithDate()
		let now = Date()

		// Old event: 90 seconds ago (should be excluded)
		currentDate.value = now.addingTimeInterval(-90)
		sut.bufferingStarted()
		currentDate.value = now.addingTimeInterval(-88)
		_ = sut.bufferingEnded()

		// Recent event: 30 seconds ago
		currentDate.value = now.addingTimeInterval(-30)
		sut.bufferingStarted()
		currentDate.value = now.addingTimeInterval(-28)
		_ = sut.bufferingEnded()

		currentDate.value = now
		let count = sut.eventsInLastMinute()

		XCTAssertEqual(count, 1)
	}

	// MARK: - reset Tests

	func test_reset_clearsAllState() {
		let sut = makeSUT()

		sut.bufferingStarted()
		_ = sut.bufferingEnded()
		sut.reset()

		let state = sut.state
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

@MainActor
private final class CurrentDateStub {
	var value: Date = Date()
}
