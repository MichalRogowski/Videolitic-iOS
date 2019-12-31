//
//  VideoReader.swift
//  Videolitic
//
//  Created by Michał Rogowski on 30/11/2019.
//  Copyright © 2019 Michał Rogowski. All rights reserved.
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
//
//

import AVFoundation

protocol VideoReaderInterface: class {

    var refreshDetectionFrameInterval: Int { get }
    var frameRateInMilliseconds: Float { get }
    var orientation: CGImagePropertyOrientation { get }

    func nextFrame() -> VideoProcessingResult.Frame?
}

final class VideoReader: VideoReaderInterface {

    // MARK: Public Properties

    let refreshDetectionFrameInterval: Int
    let frameRateInMilliseconds: Float
    lazy var orientation: CGImagePropertyOrientation = {
        let angleInDegrees = atan2(affineTransform.b, affineTransform.a) * CGFloat(180) / CGFloat.pi
        var orientation: UInt32 = 1
        switch angleInDegrees {
        case 0:
            orientation = 1 // Recording button is on the right
        case 180:
            orientation = 3 // abs(180) degree rotation recording button is on the right
        case -180:
            orientation = 3 // abs(180) degree rotation recording button is on the right
        case 90:
            orientation = 8 // 90 degree CW rotation recording button is on the top
        case -90:
            orientation = 6 // 90 degree CCW rotation recording button is on the bottom
        default:
            orientation = 1
        }
        return CGImagePropertyOrientation(rawValue: orientation) ?? .up
    }()

    // MARK: Private Properties

    private let affineTransform: CGAffineTransform
    private let assetReader: AVAssetReader
    private let millisecondsInSecond: Float32 = 1000.0
    private let videoAssetReaderOutput: AVAssetReaderTrackOutput

    // MARK: Initialisation

    init(videoAsset: AVAsset) throws {
        let videoTracks = videoAsset.tracks(withMediaType: .video)
        guard let videoTrack = videoTracks.first else {
            throw VideoliticError.videoReader(.videoTrackDoesNotExist)
        }
        assetReader = try AVAssetReader(asset: videoAsset)
        affineTransform = videoTrack.preferredTransform.inverted()
        frameRateInMilliseconds = videoTrack.nominalFrameRate
        let frameRateInSeconds = frameRateInMilliseconds * millisecondsInSecond
        refreshDetectionFrameInterval = Int(frameRateInSeconds / 3000)
        videoAssetReaderOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange])
        try prepareForReading()
    }

    // MARK: Public functions

    func nextFrame() -> VideoProcessingResult.Frame? {
        guard let sampleBuffer = videoAssetReaderOutput.copyNextSampleBuffer() else {
            return nil
        }
        let frameTime = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer)
        guard let frame = CMSampleBufferGetImageBuffer(sampleBuffer), frameTime != .invalid else {
            return nil
        }

        let timeStamp = CMTimeGetSeconds(frameTime) as TimeInterval
        return (frame, timeStamp)
    }

    // MARK: Private functions

    private func prepareForReading() throws {
        videoAssetReaderOutput.alwaysCopiesSampleData = true

        guard assetReader.canAdd(videoAssetReaderOutput) else {
            throw VideoliticError.videoReader(.assetReaderCantAddOutput)
        }

        assetReader.add(videoAssetReaderOutput)

        assetReader.startReading()
    }
}
