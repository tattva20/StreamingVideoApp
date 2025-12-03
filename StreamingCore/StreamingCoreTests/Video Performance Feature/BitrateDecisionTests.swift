//
//  BitrateDecisionTests.swift
//  StreamingCoreTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import XCTest
@testable import StreamingCore

final class BitrateDecisionTests: XCTestCase {

	// MARK: - Equatable

	func test_maintain_equalsWhenSameBitrate() {
		let decision1 = BitrateDecision.maintain(1_000_000)
		let decision2 = BitrateDecision.maintain(1_000_000)

		XCTAssertEqual(decision1, decision2)
	}

	func test_maintain_notEqualsWhenDifferentBitrate() {
		let decision1 = BitrateDecision.maintain(1_000_000)
		let decision2 = BitrateDecision.maintain(2_000_000)

		XCTAssertNotEqual(decision1, decision2)
	}

	func test_upgrade_equalsWhenSameTargetBitrate() {
		let decision1 = BitrateDecision.upgrade(to: 2_000_000)
		let decision2 = BitrateDecision.upgrade(to: 2_000_000)

		XCTAssertEqual(decision1, decision2)
	}

	func test_downgrade_equalsWhenSameBitrateAndReason() {
		let decision1 = BitrateDecision.downgrade(to: 500_000, reason: .rebuffering)
		let decision2 = BitrateDecision.downgrade(to: 500_000, reason: .rebuffering)

		XCTAssertEqual(decision1, decision2)
	}

	func test_downgrade_notEqualsWhenDifferentReason() {
		let decision1 = BitrateDecision.downgrade(to: 500_000, reason: .rebuffering)
		let decision2 = BitrateDecision.downgrade(to: 500_000, reason: .networkDegraded)

		XCTAssertNotEqual(decision1, decision2)
	}

	func test_differentDecisionTypes_notEqual() {
		let maintain = BitrateDecision.maintain(1_000_000)
		let upgrade = BitrateDecision.upgrade(to: 1_000_000)
		let downgrade = BitrateDecision.downgrade(to: 1_000_000, reason: .rebuffering)

		XCTAssertNotEqual(maintain, upgrade)
		XCTAssertNotEqual(maintain, downgrade)
		XCTAssertNotEqual(upgrade, downgrade)
	}

	// MARK: - DowngradeReason

	func test_downgradeReason_rebuffering() {
		let decision = BitrateDecision.downgrade(to: 500_000, reason: .rebuffering)

		if case .downgrade(_, let reason) = decision {
			XCTAssertEqual(reason, .rebuffering)
		} else {
			XCTFail("Expected downgrade decision")
		}
	}

	func test_downgradeReason_networkDegraded() {
		let decision = BitrateDecision.downgrade(to: 500_000, reason: .networkDegraded)

		if case .downgrade(_, let reason) = decision {
			XCTAssertEqual(reason, .networkDegraded)
		} else {
			XCTFail("Expected downgrade decision")
		}
	}

	func test_downgradeReason_memoryPressure() {
		let decision = BitrateDecision.downgrade(to: 500_000, reason: .memoryPressure)

		if case .downgrade(_, let reason) = decision {
			XCTAssertEqual(reason, .memoryPressure)
		} else {
			XCTFail("Expected downgrade decision")
		}
	}
}
