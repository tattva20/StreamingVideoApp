//
//  AnalyticsStore.swift
//  StreamingCore
//
//  Copyright by Octavio Rojas. All rights reserved.
//

import Foundation

@MainActor
public protocol AnalyticsStore: AnyObject {
    func insert(_ session: LocalPlaybackSession) async throws
    func insertEvent(_ event: LocalPlaybackEvent) async throws
    func updateSession(_ session: LocalPlaybackSession) async throws
    func retrieve(sessionID: UUID) async throws -> (session: LocalPlaybackSession, events: [LocalPlaybackEvent])?
    func retrieveAllSessions() async throws -> [LocalPlaybackSession]
    func deleteSession(_ sessionID: UUID) async throws
    func deleteAllSessions() async throws
}
