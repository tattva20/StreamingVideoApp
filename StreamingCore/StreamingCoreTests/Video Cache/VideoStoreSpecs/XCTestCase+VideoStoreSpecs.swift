//
//  XCTestCase+VideoStoreSpecs.swift
//  StreamingCoreTests
//
//  Copyright by Octavio Rojas all rights reserved.
//
import XCTest
import StreamingCore

func assertThatRetrieveDeliversEmptyOnEmptyCache(on sut: VideoStore, file: StaticString = #filePath, line: UInt = #line) {
    expect(sut, toRetrieve: .success(.none), file: file, line: line)
}

func assertThatRetrieveHasNoSideEffectsOnEmptyCache(on sut: VideoStore, file: StaticString = #filePath, line: UInt = #line) {
    expect(sut, toRetrieveTwice: .success(.none), file: file, line: line)
}

func assertThatRetrieveDeliversFoundValuesOnNonEmptyCache(on sut: VideoStore, file: StaticString = #filePath, line: UInt = #line) {
    let videos = uniqueVideoList().local
    let timestamp = Date()

    insert((videos, timestamp), to: sut)

    expect(sut, toRetrieve: .success(CachedVideos(videos: videos, timestamp: timestamp)), file: file, line: line)
}

func assertThatRetrieveHasNoSideEffectsOnNonEmptyCache(on sut: VideoStore, file: StaticString = #filePath, line: UInt = #line) {
    let videos = uniqueVideoList().local
    let timestamp = Date()

    insert((videos, timestamp), to: sut)

    expect(sut, toRetrieveTwice: .success(CachedVideos(videos: videos, timestamp: timestamp)), file: file, line: line)
}

func assertThatInsertDeliversNoErrorOnEmptyCache(on sut: VideoStore, file: StaticString = #filePath, line: UInt = #line) {
    let insertionError = insert((uniqueVideoList().local, Date()), to: sut)

    XCTAssertNil(insertionError, "Expected to insert cache successfully", file: file, line: line)
}

func assertThatInsertDeliversNoErrorOnNonEmptyCache(on sut: VideoStore, file: StaticString = #filePath, line: UInt = #line) {
    insert((uniqueVideoList().local, Date()), to: sut)

    let insertionError = insert((uniqueVideoList().local, Date()), to: sut)

    XCTAssertNil(insertionError, "Expected to override cache successfully", file: file, line: line)
}

func assertThatInsertOverridesPreviouslyInsertedCacheValues(on sut: VideoStore, file: StaticString = #filePath, line: UInt = #line) {
    insert((uniqueVideoList().local, Date()), to: sut)

    let latestVideos = uniqueVideoList().local
    let latestTimestamp = Date()
    insert((latestVideos, latestTimestamp), to: sut)

    expect(sut, toRetrieve: .success(CachedVideos(videos: latestVideos, timestamp: latestTimestamp)), file: file, line: line)
}

func assertThatDeleteDeliversNoErrorOnEmptyCache(on sut: VideoStore, file: StaticString = #filePath, line: UInt = #line) {
    let deletionError = deleteCache(from: sut)

    XCTAssertNil(deletionError, "Expected empty cache deletion to succeed", file: file, line: line)
}

func assertThatDeleteHasNoSideEffectsOnEmptyCache(on sut: VideoStore, file: StaticString = #filePath, line: UInt = #line) {
    deleteCache(from: sut)

    expect(sut, toRetrieve: .success(.none), file: file, line: line)
}

func assertThatDeleteDeliversNoErrorOnNonEmptyCache(on sut: VideoStore, file: StaticString = #filePath, line: UInt = #line) {
    insert((uniqueVideoList().local, Date()), to: sut)

    let deletionError = deleteCache(from: sut)

    XCTAssertNil(deletionError, "Expected non-empty cache deletion to succeed", file: file, line: line)
}

func assertThatDeleteEmptiesPreviouslyInsertedCache(on sut: VideoStore, file: StaticString = #filePath, line: UInt = #line) {
    insert((uniqueVideoList().local, Date()), to: sut)

    deleteCache(from: sut)

    expect(sut, toRetrieve: .success(.none), file: file, line: line)
}

@discardableResult
func insert(_ cache: (videos: [LocalVideo], timestamp: Date), to sut: VideoStore) -> Error? {
    do {
        try sut.insert(cache.videos, timestamp: cache.timestamp)
        return nil
    } catch {
        return error
    }
}

@discardableResult
func deleteCache(from sut: VideoStore) -> Error? {
    do {
        try sut.deleteCachedVideos()
        return nil
    } catch {
        return error
    }
}

func expect(_ sut: VideoStore, toRetrieve expectedResult: Result<CachedVideos?, Error>, file: StaticString = #filePath, line: UInt = #line) {
    let retrievedResult = Result { try sut.retrieve() }

    switch (retrievedResult, expectedResult) {
    case let (.success(retrievedCache), .success(expectedCache)):
        XCTAssertEqual(retrievedCache?.videos, expectedCache?.videos, file: file, line: line)
        XCTAssertEqual(retrievedCache?.timestamp, expectedCache?.timestamp, file: file, line: line)

    case (.failure, .failure):
        break

    default:
        XCTFail("Expected to retrieve \(expectedResult), got \(retrievedResult) instead", file: file, line: line)
    }
}

func expect(_ sut: VideoStore, toRetrieveTwice expectedResult: Result<CachedVideos?, Error>, file: StaticString = #filePath, line: UInt = #line) {
    expect(sut, toRetrieve: expectedResult, file: file, line: line)
    expect(sut, toRetrieve: expectedResult, file: file, line: line)
}
