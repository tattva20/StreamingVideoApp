//
//  BitrateLevelTests.swift
//  StreamingCoreTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import XCTest
@testable import StreamingCore

final class BitrateLevelTests: XCTestCase {

	// MARK: - Initialization

	func test_init_storesBitrateAndLabel() {
		let sut = BitrateLevel(bitrate: 1_500_000, label: "720p")

		XCTAssertEqual(sut.bitrate, 1_500_000)
		XCTAssertEqual(sut.label, "720p")
	}

	// MARK: - Comparable

	func test_lessThan_comparesBasedOnBitrate() {
		let low = BitrateLevel(bitrate: 500_000, label: "360p")
		let high = BitrateLevel(bitrate: 1_500_000, label: "720p")

		XCTAssertTrue(low < high)
		XCTAssertFalse(high < low)
	}

	func test_lessThan_equalBitrates_returnsFalse() {
		let level1 = BitrateLevel(bitrate: 1_000_000, label: "480p")
		let level2 = BitrateLevel(bitrate: 1_000_000, label: "480p HD")

		XCTAssertFalse(level1 < level2)
		XCTAssertFalse(level2 < level1)
	}

	// MARK: - Equatable

	func test_equatable_equalWhenBitrateAndLabelMatch() {
		let level1 = BitrateLevel(bitrate: 1_000_000, label: "480p")
		let level2 = BitrateLevel(bitrate: 1_000_000, label: "480p")

		XCTAssertEqual(level1, level2)
	}

	func test_equatable_notEqualWhenBitrateDiffers() {
		let level1 = BitrateLevel(bitrate: 1_000_000, label: "480p")
		let level2 = BitrateLevel(bitrate: 1_500_000, label: "480p")

		XCTAssertNotEqual(level1, level2)
	}

	func test_equatable_notEqualWhenLabelDiffers() {
		let level1 = BitrateLevel(bitrate: 1_000_000, label: "480p")
		let level2 = BitrateLevel(bitrate: 1_000_000, label: "480p HD")

		XCTAssertNotEqual(level1, level2)
	}

	// MARK: - Sorting

	func test_sorting_ordersByBitrateAscending() {
		let levels = [
			BitrateLevel(bitrate: 3_000_000, label: "1080p"),
			BitrateLevel(bitrate: 500_000, label: "360p"),
			BitrateLevel(bitrate: 1_500_000, label: "720p")
		]

		let sorted = levels.sorted()

		XCTAssertEqual(sorted[0].label, "360p")
		XCTAssertEqual(sorted[1].label, "720p")
		XCTAssertEqual(sorted[2].label, "1080p")
	}

	// MARK: - Standard Levels

	func test_standardLevels_containsCommonQualities() {
		let levels = BitrateLevel.standardLevels

		XCTAssertTrue(levels.count >= 4)
		XCTAssertTrue(levels.contains { $0.label.contains("360") })
		XCTAssertTrue(levels.contains { $0.label.contains("720") })
		XCTAssertTrue(levels.contains { $0.label.contains("1080") })
	}

	func test_standardLevels_areSortedByBitrate() {
		let levels = BitrateLevel.standardLevels

		for i in 0..<(levels.count - 1) {
			XCTAssertLessThan(levels[i].bitrate, levels[i + 1].bitrate)
		}
	}
}
