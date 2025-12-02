//
//  DeviceInfoProvider.swift
//  StreamingVideoApp
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import UIKit
import StreamingCore

public enum DeviceInfoProvider {
    public static func current() -> DeviceInfo {
        DeviceInfo(
            model: UIDevice.current.model,
            osVersion: UIDevice.current.systemVersion,
            networkType: nil
        )
    }
}
