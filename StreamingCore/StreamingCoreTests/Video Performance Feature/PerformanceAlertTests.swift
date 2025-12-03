//
//  PerformanceAlertTests.swift
//  StreamingCoreTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import XCTest
@testable import StreamingCore

final class PerformanceAlertTests: XCTestCase {

	// MARK: - Initialization Tests

	func test_init_setsAllProperties() {
		let id = UUID()
		let sessionID = UUID()
		let timestamp = Date()
		let alertType = PerformanceAlert.AlertType.slowStartup(duration: 5.0)

		let sut = PerformanceAlert(
			id: id,
			sessionID: sessionID,
			type: alertType,
			severity: .warning,
			timestamp: timestamp,
			message: "Slow startup detected",
			suggestion: "Check network connection"
		)

		XCTAssertEqual(sut.id, id)
		XCTAssertEqual(sut.sessionID, sessionID)
		XCTAssertEqual(sut.type, alertType)
		XCTAssertEqual(sut.severity, .warning)
		XCTAssertEqual(sut.timestamp, timestamp)
		XCTAssertEqual(sut.message, "Slow startup detected")
		XCTAssertEqual(sut.suggestion, "Check network connection")
	}

	func test_init_withNilSuggestion() {
		let sut = makeAlert(suggestion: nil)
		XCTAssertNil(sut.suggestion)
	}

	// MARK: - AlertType Equality Tests

	func test_slowStartup_isEqualWithSameDuration() {
		XCTAssertEqual(
			PerformanceAlert.AlertType.slowStartup(duration: 5.0),
			PerformanceAlert.AlertType.slowStartup(duration: 5.0)
		)
	}

	func test_slowStartup_isNotEqualWithDifferentDuration() {
		XCTAssertNotEqual(
			PerformanceAlert.AlertType.slowStartup(duration: 5.0),
			PerformanceAlert.AlertType.slowStartup(duration: 6.0)
		)
	}

	func test_frequentRebuffering_isEqualWithSameValues() {
		XCTAssertEqual(
			PerformanceAlert.AlertType.frequentRebuffering(count: 5, ratio: 0.05),
			PerformanceAlert.AlertType.frequentRebuffering(count: 5, ratio: 0.05)
		)
	}

	func test_frequentRebuffering_isNotEqualWithDifferentCount() {
		XCTAssertNotEqual(
			PerformanceAlert.AlertType.frequentRebuffering(count: 5, ratio: 0.05),
			PerformanceAlert.AlertType.frequentRebuffering(count: 6, ratio: 0.05)
		)
	}

	func test_prolongedBuffering_isEqualWithSameDuration() {
		XCTAssertEqual(
			PerformanceAlert.AlertType.prolongedBuffering(duration: 10.0),
			PerformanceAlert.AlertType.prolongedBuffering(duration: 10.0)
		)
	}

	func test_memoryPressure_isEqualWithSameLevel() {
		XCTAssertEqual(
			PerformanceAlert.AlertType.memoryPressure(level: .critical),
			PerformanceAlert.AlertType.memoryPressure(level: .critical)
		)
	}

	func test_networkDegradation_isEqualWithSameQualityChange() {
		XCTAssertEqual(
			PerformanceAlert.AlertType.networkDegradation(from: .excellent, to: .fair),
			PerformanceAlert.AlertType.networkDegradation(from: .excellent, to: .fair)
		)
	}

	func test_playbackStalled_isEqualToSameCase() {
		XCTAssertEqual(
			PerformanceAlert.AlertType.playbackStalled,
			PerformanceAlert.AlertType.playbackStalled
		)
	}

	func test_qualityDowngrade_isEqualWithSameBitrates() {
		XCTAssertEqual(
			PerformanceAlert.AlertType.qualityDowngrade(fromBitrate: 6_000_000, toBitrate: 3_000_000),
			PerformanceAlert.AlertType.qualityDowngrade(fromBitrate: 6_000_000, toBitrate: 3_000_000)
		)
	}

	func test_differentAlertTypes_areNotEqual() {
		XCTAssertNotEqual(
			PerformanceAlert.AlertType.slowStartup(duration: 5.0),
			PerformanceAlert.AlertType.playbackStalled
		)
		XCTAssertNotEqual(
			PerformanceAlert.AlertType.prolongedBuffering(duration: 10.0),
			PerformanceAlert.AlertType.memoryPressure(level: .critical)
		)
	}

	// MARK: - Severity Tests

	func test_severity_comparable() {
		XCTAssertTrue(PerformanceAlert.Severity.info < PerformanceAlert.Severity.warning)
		XCTAssertTrue(PerformanceAlert.Severity.warning < PerformanceAlert.Severity.critical)
		XCTAssertTrue(PerformanceAlert.Severity.info < PerformanceAlert.Severity.critical)
	}

	func test_severity_equality() {
		XCTAssertEqual(PerformanceAlert.Severity.info, PerformanceAlert.Severity.info)
		XCTAssertEqual(PerformanceAlert.Severity.warning, PerformanceAlert.Severity.warning)
		XCTAssertEqual(PerformanceAlert.Severity.critical, PerformanceAlert.Severity.critical)
	}

	// MARK: - Identifiable Tests

	func test_identifiable_usesIDProperty() {
		let id = UUID()
		let sut = makeAlert(id: id)
		XCTAssertEqual(sut.id, id)
	}

	// MARK: - Sendable Tests

	func test_performanceAlert_isSendable() {
		let alert: any Sendable = makeAlert()
		XCTAssertNotNil(alert)
	}

	// MARK: - Helpers

	private func makeAlert(
		id: UUID = UUID(),
		sessionID: UUID = UUID(),
		type: PerformanceAlert.AlertType = .playbackStalled,
		severity: PerformanceAlert.Severity = .warning,
		timestamp: Date = Date(),
		message: String = "Test message",
		suggestion: String? = "Test suggestion"
	) -> PerformanceAlert {
		PerformanceAlert(
			id: id,
			sessionID: sessionID,
			type: type,
			severity: severity,
			timestamp: timestamp,
			message: message,
			suggestion: suggestion
		)
	}
}
