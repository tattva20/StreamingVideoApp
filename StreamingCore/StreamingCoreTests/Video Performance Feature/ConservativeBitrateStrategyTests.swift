//
//  ConservativeBitrateStrategyTests.swift
//  StreamingCoreTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import XCTest
@testable import StreamingCore

final class ConservativeBitrateStrategyTests: XCTestCase {

	// MARK: - Initial Bitrate

	func test_initialBitrate_returnsLowestForOfflineNetwork() {
		let sut = makeSUT()
		let levels = BitrateLevel.standardLevels

		let bitrate = sut.initialBitrate(for: .offline, availableLevels: levels)

		XCTAssertEqual(bitrate, levels.first?.bitrate)
	}

	func test_initialBitrate_returnsLowestForPoorNetwork() {
		let sut = makeSUT()
		let levels = BitrateLevel.standardLevels

		let bitrate = sut.initialBitrate(for: .poor, availableLevels: levels)

		XCTAssertEqual(bitrate, levels.first?.bitrate)
	}

	func test_initialBitrate_returnsMediumForFairNetwork() {
		let sut = makeSUT()
		let levels = BitrateLevel.standardLevels

		let bitrate = sut.initialBitrate(for: .fair, availableLevels: levels)

		// Should return middle level (index 1 or 2 depending on levels)
		let middleIndex = levels.count / 3
		XCTAssertEqual(bitrate, levels[middleIndex].bitrate)
	}

	func test_initialBitrate_returnsMediumHighForGoodNetwork() {
		let sut = makeSUT()
		let levels = BitrateLevel.standardLevels

		let bitrate = sut.initialBitrate(for: .good, availableLevels: levels)

		// Should return middle-high level
		let index = min(levels.count * 2 / 3, levels.count - 1)
		XCTAssertEqual(bitrate, levels[index].bitrate)
	}

	func test_initialBitrate_returnsHighestForExcellentNetwork() {
		let sut = makeSUT()
		let levels = BitrateLevel.standardLevels

		let bitrate = sut.initialBitrate(for: .excellent, availableLevels: levels)

		XCTAssertEqual(bitrate, levels.last?.bitrate)
	}

	// MARK: - Should Upgrade

	func test_shouldUpgrade_returnsNil_whenAlreadyAtHighestLevel() {
		let sut = makeSUT()
		let levels = BitrateLevel.standardLevels
		let highestBitrate = levels.last!.bitrate

		let upgrade = sut.shouldUpgrade(
			currentBitrate: highestBitrate,
			bufferHealth: 1.0,
			networkQuality: .excellent,
			availableLevels: levels
		)

		XCTAssertNil(upgrade)
	}

	func test_shouldUpgrade_returnsNil_whenBufferHealthLow() {
		let sut = makeSUT()
		let levels = BitrateLevel.standardLevels

		let upgrade = sut.shouldUpgrade(
			currentBitrate: levels[0].bitrate,
			bufferHealth: 0.3, // Below threshold
			networkQuality: .excellent,
			availableLevels: levels
		)

		XCTAssertNil(upgrade)
	}

	func test_shouldUpgrade_returnsNextLevel_whenBufferHealthHigh() {
		let sut = makeSUT()
		let levels = BitrateLevel.standardLevels

		let upgrade = sut.shouldUpgrade(
			currentBitrate: levels[0].bitrate,
			bufferHealth: 0.9, // High buffer health
			networkQuality: .excellent,
			availableLevels: levels
		)

		XCTAssertEqual(upgrade, levels[1].bitrate)
	}

	func test_shouldUpgrade_returnsNil_whenNetworkPoor() {
		let sut = makeSUT()
		let levels = BitrateLevel.standardLevels

		let upgrade = sut.shouldUpgrade(
			currentBitrate: levels[0].bitrate,
			bufferHealth: 0.9,
			networkQuality: .poor,
			availableLevels: levels
		)

		XCTAssertNil(upgrade)
	}

	// MARK: - Should Downgrade

	func test_shouldDowngrade_returnsNil_whenAlreadyAtLowestLevel() {
		let sut = makeSUT()
		let levels = BitrateLevel.standardLevels
		let lowestBitrate = levels.first!.bitrate

		let downgrade = sut.shouldDowngrade(
			currentBitrate: lowestBitrate,
			rebufferingRatio: 0.5,
			networkQuality: .poor,
			availableLevels: levels
		)

		XCTAssertNil(downgrade)
	}

	func test_shouldDowngrade_returnsLowerLevel_whenRebufferingHigh() {
		let sut = makeSUT()
		let levels = BitrateLevel.standardLevels

		let downgrade = sut.shouldDowngrade(
			currentBitrate: levels[2].bitrate,
			rebufferingRatio: 0.1, // 10% rebuffering
			networkQuality: .good,
			availableLevels: levels
		)

		XCTAssertEqual(downgrade, levels[1].bitrate)
	}

	func test_shouldDowngrade_returnsLowerLevel_whenNetworkDegraded() {
		let sut = makeSUT()
		let levels = BitrateLevel.standardLevels

		let downgrade = sut.shouldDowngrade(
			currentBitrate: levels[3].bitrate,
			rebufferingRatio: 0.0, // No rebuffering
			networkQuality: .poor,
			availableLevels: levels
		)

		XCTAssertEqual(downgrade, levels[2].bitrate)
	}

	func test_shouldDowngrade_returnsNil_whenConditionsGood() {
		let sut = makeSUT()
		let levels = BitrateLevel.standardLevels

		let downgrade = sut.shouldDowngrade(
			currentBitrate: levels[2].bitrate,
			rebufferingRatio: 0.0,
			networkQuality: .excellent,
			availableLevels: levels
		)

		XCTAssertNil(downgrade)
	}

	// MARK: - Helpers

	private func makeSUT(
		file: StaticString = #filePath,
		line: UInt = #line
	) -> ConservativeBitrateStrategy {
		let sut = ConservativeBitrateStrategy()
		return sut
	}
}
