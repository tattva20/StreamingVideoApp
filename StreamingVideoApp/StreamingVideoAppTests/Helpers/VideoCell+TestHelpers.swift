import UIKit
import StreamingCoreiOS

extension VideoCell {
	var renderedImage: Data? {
		return videoImageView.image?.pngData()
	}
}
