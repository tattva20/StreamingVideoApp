//
//  PlaybackSessionTests.swift
//  StreamingCoreTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import XCTest
import StreamingCore

@MainActor
final class PlaybackSessionTests: XCTestCase {

    // MARK: - DeviceInfo Tests

    func test_deviceInfo_initCreatesWithCorrectProperties() {
        let deviceInfo = DeviceInfo(
            model: "iPhone",
            osVersion: "17.0",
            networkType: "WiFi"
        )

        XCTAssertEqual(deviceInfo.model, "iPhone")
        XCTAssertEqual(deviceInfo.osVersion, "17.0")
        XCTAssertEqual(deviceInfo.networkType, "WiFi")
    }

    func test_deviceInfo_supportsNilNetworkType() {
        let deviceInfo = DeviceInfo(
            model: "iPhone",
            osVersion: "17.0",
            networkType: nil
        )

        XCTAssertNil(deviceInfo.networkType)
    }

    func test_deviceInfo_isEquatableWithSameValues() {
        let deviceInfo1 = DeviceInfo(model: "iPhone", osVersion: "17.0", networkType: "WiFi")
        let deviceInfo2 = DeviceInfo(model: "iPhone", osVersion: "17.0", networkType: "WiFi")

        XCTAssertEqual(deviceInfo1, deviceInfo2)
    }

    func test_deviceInfo_isNotEqualWithDifferentModel() {
        let deviceInfo1 = DeviceInfo(model: "iPhone", osVersion: "17.0", networkType: "WiFi")
        let deviceInfo2 = DeviceInfo(model: "iPad", osVersion: "17.0", networkType: "WiFi")

        XCTAssertNotEqual(deviceInfo1, deviceInfo2)
    }

    func test_deviceInfo_isNotEqualWithDifferentNetworkType() {
        let deviceInfo1 = DeviceInfo(model: "iPhone", osVersion: "17.0", networkType: "WiFi")
        let deviceInfo2 = DeviceInfo(model: "iPhone", osVersion: "17.0", networkType: "Cellular")

        XCTAssertNotEqual(deviceInfo1, deviceInfo2)
    }

    func test_deviceInfo_isSendable() async {
        let deviceInfo = DeviceInfo(model: "iPhone", osVersion: "17.0", networkType: "WiFi")

        let result = await Task.detached {
            return deviceInfo
        }.value

        XCTAssertEqual(result.model, "iPhone")
    }

    func test_deviceInfo_isCodable() throws {
        let deviceInfo = DeviceInfo(model: "iPhone", osVersion: "17.0", networkType: "WiFi")

        let encoded = try JSONEncoder().encode(deviceInfo)
        let decoded = try JSONDecoder().decode(DeviceInfo.self, from: encoded)

        XCTAssertEqual(decoded, deviceInfo)
    }

    func test_deviceInfo_isCodableWithNilNetworkType() throws {
        let deviceInfo = DeviceInfo(model: "iPhone", osVersion: "17.0", networkType: nil)

        let encoded = try JSONEncoder().encode(deviceInfo)
        let decoded = try JSONDecoder().decode(DeviceInfo.self, from: encoded)

        XCTAssertEqual(decoded, deviceInfo)
        XCTAssertNil(decoded.networkType)
    }

    // MARK: - PlaybackSession Tests

    func test_playbackSession_initCreatesWithCorrectProperties() {
        let id = UUID()
        let videoID = UUID()
        let videoTitle = "Test Video"
        let startTime = Date()
        let deviceInfo = DeviceInfo(model: "iPhone", osVersion: "17.0", networkType: "WiFi")
        let appVersion = "1.0.0"

        let session = PlaybackSession(
            id: id,
            videoID: videoID,
            videoTitle: videoTitle,
            startTime: startTime,
            endTime: nil,
            deviceInfo: deviceInfo,
            appVersion: appVersion
        )

        XCTAssertEqual(session.id, id)
        XCTAssertEqual(session.videoID, videoID)
        XCTAssertEqual(session.videoTitle, videoTitle)
        XCTAssertEqual(session.startTime, startTime)
        XCTAssertNil(session.endTime)
        XCTAssertEqual(session.deviceInfo, deviceInfo)
        XCTAssertEqual(session.appVersion, appVersion)
    }

    func test_playbackSession_supportsEndTime() {
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(60)

        let session = PlaybackSession(
            id: UUID(),
            videoID: UUID(),
            videoTitle: "Test Video",
            startTime: startTime,
            endTime: endTime,
            deviceInfo: DeviceInfo(model: "iPhone", osVersion: "17.0", networkType: nil),
            appVersion: "1.0.0"
        )

        XCTAssertEqual(session.endTime, endTime)
    }

    func test_playbackSession_isEquatableWithSameValues() {
        let id = UUID()
        let videoID = UUID()
        let startTime = Date()
        let deviceInfo = DeviceInfo(model: "iPhone", osVersion: "17.0", networkType: "WiFi")

        let session1 = PlaybackSession(
            id: id,
            videoID: videoID,
            videoTitle: "Test Video",
            startTime: startTime,
            endTime: nil,
            deviceInfo: deviceInfo,
            appVersion: "1.0.0"
        )

        let session2 = PlaybackSession(
            id: id,
            videoID: videoID,
            videoTitle: "Test Video",
            startTime: startTime,
            endTime: nil,
            deviceInfo: deviceInfo,
            appVersion: "1.0.0"
        )

        XCTAssertEqual(session1, session2)
    }

    func test_playbackSession_isNotEqualWithDifferentID() {
        let videoID = UUID()
        let startTime = Date()
        let deviceInfo = DeviceInfo(model: "iPhone", osVersion: "17.0", networkType: "WiFi")

        let session1 = PlaybackSession(
            id: UUID(),
            videoID: videoID,
            videoTitle: "Test Video",
            startTime: startTime,
            endTime: nil,
            deviceInfo: deviceInfo,
            appVersion: "1.0.0"
        )

        let session2 = PlaybackSession(
            id: UUID(),
            videoID: videoID,
            videoTitle: "Test Video",
            startTime: startTime,
            endTime: nil,
            deviceInfo: deviceInfo,
            appVersion: "1.0.0"
        )

        XCTAssertNotEqual(session1, session2)
    }

    func test_playbackSession_isNotEqualWithDifferentVideoTitle() {
        let id = UUID()
        let videoID = UUID()
        let startTime = Date()
        let deviceInfo = DeviceInfo(model: "iPhone", osVersion: "17.0", networkType: "WiFi")

        let session1 = PlaybackSession(
            id: id,
            videoID: videoID,
            videoTitle: "Test Video 1",
            startTime: startTime,
            endTime: nil,
            deviceInfo: deviceInfo,
            appVersion: "1.0.0"
        )

        let session2 = PlaybackSession(
            id: id,
            videoID: videoID,
            videoTitle: "Test Video 2",
            startTime: startTime,
            endTime: nil,
            deviceInfo: deviceInfo,
            appVersion: "1.0.0"
        )

        XCTAssertNotEqual(session1, session2)
    }

    func test_playbackSession_isSendable() async {
        let session = PlaybackSession(
            id: UUID(),
            videoID: UUID(),
            videoTitle: "Test Video",
            startTime: Date(),
            endTime: nil,
            deviceInfo: DeviceInfo(model: "iPhone", osVersion: "17.0", networkType: nil),
            appVersion: "1.0.0"
        )

        let result = await Task.detached {
            return session
        }.value

        XCTAssertEqual(result.videoTitle, "Test Video")
    }
}
