//
//  PlaybackErrorTests.swift
//  StreamingCoreTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import XCTest
@testable import StreamingCore

final class PlaybackErrorTests: XCTestCase {

	// MARK: - Equality

	func test_equality_loadFailedErrorsWithSameReasonAreEqual() {
		let reason = "File not found"
		XCTAssertEqual(
			PlaybackError.loadFailed(reason: reason),
			PlaybackError.loadFailed(reason: reason)
		)
	}

	func test_equality_loadFailedErrorsWithDifferentReasonsAreNotEqual() {
		XCTAssertNotEqual(
			PlaybackError.loadFailed(reason: "File not found"),
			PlaybackError.loadFailed(reason: "Access denied")
		)
	}

	func test_equality_networkErrorsWithSameReasonAreEqual() {
		let reason = "Timeout"
		XCTAssertEqual(
			PlaybackError.networkError(reason: reason),
			PlaybackError.networkError(reason: reason)
		)
	}

	func test_equality_decodingErrorsWithSameReasonAreEqual() {
		let reason = "Invalid codec"
		XCTAssertEqual(
			PlaybackError.decodingError(reason: reason),
			PlaybackError.decodingError(reason: reason)
		)
	}

	func test_equality_drmErrorsWithSameReasonAreEqual() {
		let reason = "License expired"
		XCTAssertEqual(
			PlaybackError.drmError(reason: reason),
			PlaybackError.drmError(reason: reason)
		)
	}

	func test_equality_unknownErrorsWithSameReasonAreEqual() {
		let reason = "Unknown error"
		XCTAssertEqual(
			PlaybackError.unknown(reason: reason),
			PlaybackError.unknown(reason: reason)
		)
	}

	func test_equality_differentErrorTypesAreNotEqual() {
		let reason = "Error"
		XCTAssertNotEqual(
			PlaybackError.loadFailed(reason: reason),
			PlaybackError.networkError(reason: reason)
		)
		XCTAssertNotEqual(
			PlaybackError.networkError(reason: reason),
			PlaybackError.decodingError(reason: reason)
		)
		XCTAssertNotEqual(
			PlaybackError.decodingError(reason: reason),
			PlaybackError.drmError(reason: reason)
		)
	}

	// MARK: - isRecoverable

	func test_isRecoverable_returnsTrueForNetworkError() {
		let error = PlaybackError.networkError(reason: "Timeout")
		XCTAssertTrue(error.isRecoverable)
	}

	func test_isRecoverable_returnsFalseForLoadFailed() {
		let error = PlaybackError.loadFailed(reason: "File not found")
		XCTAssertFalse(error.isRecoverable)
	}

	func test_isRecoverable_returnsFalseForDecodingError() {
		let error = PlaybackError.decodingError(reason: "Invalid codec")
		XCTAssertFalse(error.isRecoverable)
	}

	func test_isRecoverable_returnsFalseForDrmError() {
		let error = PlaybackError.drmError(reason: "License expired")
		XCTAssertFalse(error.isRecoverable)
	}

	func test_isRecoverable_returnsFalseForUnknown() {
		let error = PlaybackError.unknown(reason: "Unknown error")
		XCTAssertFalse(error.isRecoverable)
	}

	// MARK: - Error Protocol Conformance

	func test_conformsToErrorProtocol() {
		let error: Error = PlaybackError.networkError(reason: "Test")
		XCTAssertNotNil(error)
	}

	// MARK: - Sendable Conformance

	func test_canBeSentAcrossConcurrencyBoundary() async {
		let error = PlaybackError.networkError(reason: "Test")

		let result = await Task.detached {
			return error
		}.value

		XCTAssertEqual(result, error)
	}
}
