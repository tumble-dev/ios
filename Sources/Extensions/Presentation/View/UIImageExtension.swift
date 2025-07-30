//
//  UIImageExtension.swift
//  Tumble
//
//  Created by Adis Veletanlic on 5/5/23.
//

import Foundation
import UIKit

extension UIImage {
    func resizeImage(targetSize: CGSize) -> UIImage {
        let size = self.size
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height

        // Determine the scaling factor that preserves aspect ratio
        let scaleFactor = min(widthRatio, heightRatio)

        // Compute the new image size that preserves aspect ratio
        let scaledSize = CGSize(width: size.width * scaleFactor, height: size.height * scaleFactor)

        // Draw and return the resized UIImage
        let renderer = UIGraphicsImageRenderer(size: scaledSize)
        let resizedImage = renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: scaledSize))
        }
        return resizedImage
    }
}
