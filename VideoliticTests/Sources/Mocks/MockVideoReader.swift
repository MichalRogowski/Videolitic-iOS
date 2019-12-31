//
//  MockVideoReader.swift
//  VideoliticTests
//
//  Created by Michał Rogowski on 03/01/2020.
//  Copyright © 2020 Michał Rogowski. All rights reserved.
//

import AVFoundation
import Combine
import Speech
import UIKit
@testable import Videolitic

final class MockVideoReader: VideoReaderInterface {

    var expectedRefreshDetectionFrameInterval: Int = 0
    var expectedFrameRateInMilliseconds: Float = 0
    var expectedOrientation: CGImagePropertyOrientation = .up
    var expectedFrame: VideoProcessingResult.Frame?

    var refreshDetectionFrameInterval: Int { expectedRefreshDetectionFrameInterval }

    var frameRateInMilliseconds: Float { expectedFrameRateInMilliseconds }

    var orientation: CGImagePropertyOrientation { expectedOrientation }

    func nextFrame() -> VideoProcessingResult.Frame? {
        return expectedFrame
    }

    func pixelBufferFrom(image: UIImage) -> CVPixelBuffer {
        var pixelBuffer: CVPixelBuffer?
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        CVPixelBufferCreate(kCFAllocatorDefault, Int(image.size.width), Int(image.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        return pixelBuffer!
    }

    func imageFrom(color: UIColor, width: CGFloat, height: CGFloat) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        UIGraphicsBeginImageContext(rect.size)
        color.set()
        UIRectFill(rect)
        guard let testImage = UIGraphicsGetImageFromCurrentImageContext() else {
            return UIImage()
        }
        UIGraphicsEndImageContext()
        return testImage
    }
}
