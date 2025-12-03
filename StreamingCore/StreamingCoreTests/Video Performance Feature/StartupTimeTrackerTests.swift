//
//  StartupTimeTrackerTests.swift
//  StreamingCoreTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import XCTest
@testable import StreamingCore

final class StartupTimeTrackerTests: XCTestCase {

	// MARK: - Initial State Tests

	func test_init_measurementIsNil() {
		let sut = makeSUT()
		XCTAssertNil(sut.measurement)
	}

	// MARK: - recordLoadStart Tests

	func test_recordLoadStart_createsMeasurement() {
		let sut = makeSUT()
		let startTime = Date()

		sut.recordLoadStart(at: startTime)

		XCTAssertNotNil(sut.measurement)
		XCTAssertEqual(sut.measurement?.loadStartTime, startTime)
		XCTAssertNil(sut.measurement?.firstFrameTime)
	}

	func test_recordLoadStart_doesNotOverwriteExistingMeasurement() {
		let sut = makeSUT()
		let firstStartTime = Date()
		let secondStartTime = firstStartTime.addingTimeInterval(10)

		sut.recordLoadStart(at: firstStartTime)
		sut.recordLoadStart(at: secondStartTime)

		XCTAssertEqual(sut.measurement?.loadStartTime, firstStartTime)
	}

	// MARK: - recordFirstFrame Tests

	func test_recordFirstFrame_setsFirstFrameTime() {
		let sut = makeSUT()
		let startTime = Date()
		let firstFrameTime = startTime.addingTimeInterval(1.5)

		sut.recordLoadStart(at: startTime)
		sut.recordFirstFrame(at: firstFrameTime)

		XCTAssertEqual(sut.measurement?.firstFrameTime, firstFrameTime)
	}

	func test_recordFirstFrame_doesNothingWithoutLoadStart() {
		let sut = makeSUT()
		let firstFrameTime = Date()

		sut.recordFirstFrame(at: firstFrameTime)

		XCTAssertNil(sut.measurement)
	}

	func test_recordFirstFrame_doesNotOverwriteExistingFirstFrame() {
		let sut = makeSUT()
		let startTime = Date()
		let firstFrameTime = startTime.addingTimeInterval(1.5)
		let secondFrameTime = startTime.addingTimeInterval(3.0)

		sut.recordLoadStart(at: startTime)
		sut.recordFirstFrame(at: firstFrameTime)
		sut.recordFirstFrame(at: secondFrameTime)

		XCTAssertEqual(sut.measurement?.firstFrameTime, firstFrameTime)
	}

	// MARK: - Measurement Tests

	func test_measurement_isNotCompleteBeforeFirstFrame() {
		let sut = makeSUT()
		sut.recordLoadStart(at: Date())

		XCTAssertFalse(sut.measurement?.isComplete ?? true)
	}

	func test_measurement_isCompleteAfterFirstFrame() {
		let sut = makeSUT()
		let startTime = Date()
		sut.recordLoadStart(at: startTime)
		sut.recordFirstFrame(at: startTime.addingTimeInterval(1.5))

		XCTAssertTrue(sut.measurement?.isComplete ?? false)
	}

	// MARK: - timeToFirstFrame Tests

	func test_measurement_timeToFirstFrame_calculatesCorrectly() {
		let sut = makeSUT()
		let startTime = Date()
		let expectedDuration: TimeInterval = 2.5
		let firstFrameTime = startTime.addingTimeInterval(expectedDuration)

		sut.recordLoadStart(at: startTime)
		sut.recordFirstFrame(at: firstFrameTime)

		let timeToFirstFrame = try! XCTUnwrap(sut.measurement?.timeToFirstFrame)
		XCTAssertEqual(timeToFirstFrame, expectedDuration, accuracy: 0.001)
	}

	func test_measurement_timeToFirstFrame_isNilWithoutFirstFrame() {
		let sut = makeSUT()
		sut.recordLoadStart(at: Date())

		XCTAssertNil(sut.measurement?.timeToFirstFrame)
	}

	// MARK: - reset Tests

	func test_reset_clearsMeasurement() {
		let sut = makeSUT()
		sut.recordLoadStart(at: Date())
		sut.recordFirstFrame(at: Date())

		sut.reset()

		XCTAssertNil(sut.measurement)
	}

	// MARK: - Thread Safety Tests

	func test_concurrentAccess_doesNotCrash() {
		let sut = makeSUT()
		let expectation = self.expectation(description: "Concurrent access completes")
		expectation.expectedFulfillmentCount = 100

		DispatchQueue.concurrentPerform(iterations: 100) { iteration in
			let time = Date().addingTimeInterval(Double(iteration) * 0.001)
			if iteration % 3 == 0 {
				sut.recordLoadStart(at: time)
			} else if iteration % 3 == 1 {
				sut.recordFirstFrame(at: time)
			} else {
				_ = sut.measurement
			}
			expectation.fulfill()
		}

		wait(for: [expectation], timeout: 5.0)
	}

	// MARK: - Sendable Tests

	func test_startupTimeTracker_isSendable() {
		let tracker: any Sendable = makeSUT()
		XCTAssertNotNil(tracker)
	}

	// MARK: - Helpers

	private func makeSUT() -> StartupTimeTracker {
		StartupTimeTracker()
	}
}
