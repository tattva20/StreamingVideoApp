//
//  HTTPURLResponse+StatusCode.swift
//  StreamingCore
//
//  Created by Claude on 30/11/25.
//

import Foundation

extension HTTPURLResponse {
    private static var OK_200: Int { return 200 }

    var isOK: Bool {
        return statusCode == HTTPURLResponse.OK_200
    }
}
