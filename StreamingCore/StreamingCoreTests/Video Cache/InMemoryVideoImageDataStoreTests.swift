import XCTest
import StreamingCore

@MainActor
class InMemoryVideoImageDataStoreTests: XCTestCase, VideoImageDataStoreSpecs {

    func test_retrieveImageData_deliversNotFoundWhenEmpty() throws {
        let sut = makeSUT()

        assertThatRetrieveImageDataDeliversNotFoundOnEmptyCache(on: sut)
    }

    func test_retrieveImageData_deliversNotFoundWhenStoredDataURLDoesNotMatch() throws {
        let sut = makeSUT()

        assertThatRetrieveImageDataDeliversNotFoundWhenStoredDataURLDoesNotMatch(on: sut)
    }

    func test_retrieveImageData_deliversFoundDataWhenThereIsAStoredImageDataMatchingURL() throws {
        let sut = makeSUT()

        assertThatRetrieveImageDataDeliversFoundDataWhenThereIsAStoredImageDataMatchingURL(on: sut)
    }

    func test_retrieveImageData_deliversLastInsertedValue() throws {
        let sut = makeSUT()

        assertThatRetrieveImageDataDeliversLastInsertedValueForURL(on: sut)
    }

    // MARK: - Helpers

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> InMemoryVideoStore {
        let sut = InMemoryVideoStore()
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
}
