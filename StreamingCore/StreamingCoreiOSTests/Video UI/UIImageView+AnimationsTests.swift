//
//  UIImageView+AnimationsTests.swift
//  StreamingCoreiOSTests
//
//  Copyright by Octavio Rojas all rights reserved.
//
import XCTest
@testable import StreamingCoreiOS

class UIImageViewAnimationsTests: XCTestCase {

    func test_setImageAnimated_setsImageWhenNil() {
        let imageView = UIImageView()

        imageView.setImageAnimated(nil)

        XCTAssertNil(imageView.image)
    }

    func test_setImageAnimated_setsImageWhenNotNil() {
        let imageView = UIImageView()
        let image = UIImage.make(withColor: .red)

        imageView.setImageAnimated(image)

        XCTAssertEqual(imageView.image, image)
    }

    func test_setImageAnimated_doesNotChangeAlphaWhenImageIsNil() {
        let imageView = UIImageView()
        imageView.alpha = 0.5

        imageView.setImageAnimated(nil)

        XCTAssertEqual(imageView.alpha, 0.5, "Expected alpha to remain unchanged when image is nil")
    }
}

// MARK: - Helpers removed - now using shared UIImage+TestHelpers
