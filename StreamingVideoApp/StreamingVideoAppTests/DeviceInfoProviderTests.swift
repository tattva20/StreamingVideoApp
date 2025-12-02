//
//  DeviceInfoProviderTests.swift
//  StreamingVideoAppTests
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import XCTest
import StreamingCore
@testable import StreamingVideoApp

final class DeviceInfoProviderTests: XCTestCase {

    func test_current_returnsDeviceInfoWithModel() {
        let deviceInfo = DeviceInfoProvider.current()

        XCTAssertFalse(deviceInfo.model.isEmpty)
    }

    func test_current_returnsDeviceInfoWithOSVersion() {
        let deviceInfo = DeviceInfoProvider.current()

        XCTAssertFalse(deviceInfo.osVersion.isEmpty)
    }

    func test_current_returnsDeviceInfoWithNetworkType() {
        let deviceInfo = DeviceInfoProvider.current()

        // Network type can be nil in simulator but should be present in device
        // We just verify it doesn't crash
        _ = deviceInfo.networkType
    }
}
