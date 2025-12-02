//
//  VideoListSnapshotTests.swift
//  StreamingCoreiOSTests
//
//  Copyright by Octavio Rojas all rights reserved.
//
import XCTest
import StreamingCoreiOS
@testable import StreamingCore

@MainActor
class VideoListSnapshotTests: XCTestCase {

    func test_emptyVideoList() {
        let sut = makeSUT()

        sut.display(emptyList())

        assert(snapshot: sut.snapshot(for: .iPhone(style: .light)), named: "EMPTY_VIDEO_LIST_light")
        assert(snapshot: sut.snapshot(for: .iPhone(style: .dark)), named: "EMPTY_VIDEO_LIST_dark")
    }

    func test_videoListWithErrorMessage() {
        let sut = makeSUT()

        sut.display(.error(message: "This is a\nmulti-line\nerror message"))

        assert(snapshot: sut.snapshot(for: .iPhone(style: .light)), named: "VIDEO_LIST_WITH_ERROR_MESSAGE_light")
        assert(snapshot: sut.snapshot(for: .iPhone(style: .dark)), named: "VIDEO_LIST_WITH_ERROR_MESSAGE_dark")
        assert(snapshot: sut.snapshot(for: .iPhone(style: .light, contentSize: .extraExtraExtraLarge)), named: "VIDEO_LIST_WITH_ERROR_MESSAGE_light_extraExtraExtraLarge")
    }

    // MARK: - Helpers

    private func makeSUT() -> ListViewController {
        let controller = ListViewController()
        controller.loadViewIfNeeded()
        controller.tableView.separatorStyle = .none
        controller.tableView.showsVerticalScrollIndicator = false
        controller.tableView.showsHorizontalScrollIndicator = false
        return controller
    }

    private func emptyList() -> [CellController] {
        return []
    }
}
