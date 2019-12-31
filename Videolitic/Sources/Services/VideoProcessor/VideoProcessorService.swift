//
//  VideoProcessorService.swift
//  Videolitic
//
//  Created by Michał Rogowski on 29/11/2019.
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

import Accelerate
import AVFoundation
import Combine
import Photos
import Speech
import UIKit
import VideoToolbox
import Vision

protocol VideoProcessorServiceInterface: class {

    var framePublisher: Published<VideoProcessingResult.Frame?>.Publisher { get }

    func startTracking() throws -> AnyPublisher<([SFTranscriptionSegment], [Participant]), Error>
    func stopTracking()
}

final class VideoProcessorService: VideoProcessorServiceInterface {

    // MARK: Public properties

    var framePublisher: Published<VideoProcessingResult.Frame?>.Publisher { $frame }

    // MARK: Private properties

    @Published private var frame: VideoProcessingResult.Frame?

    private let audioProcessor: AudioProcessorServiceInterface
    private let backgroundQueue = DispatchQueue(label: "VideoProcessorServiceQueue")
    private var cancelRequested = false
    private let faceComputingService: FaceComputingServiceInterface
    private let videoReader: VideoReaderInterface

    // MARK: Initialisation

    init(audioProcessor: AudioProcessorServiceInterface, faceComputingService: FaceComputingServiceInterface, videoReader: VideoReaderInterface) throws {
        self.audioProcessor = audioProcessor
        self.videoReader = videoReader
        self.faceComputingService = faceComputingService
    }

    // MARK: Public functions

    func startTracking() -> AnyPublisher<([SFTranscriptionSegment], [Participant]), Error> {
        guard let frame = videoReader.nextFrame() else {
            return Future<([SFTranscriptionSegment], [Participant]), Error> {
                $0(.failure(VideoliticError.videoProcessorService(.firstFrameReadFailed)))
            }
            .eraseToAnyPublisher()
        }

        self.frame = frame
        cancelRequested = false

        return Publishers.Zip(audioProcessor.recognizeSpeechPublisher, startDetecting())
            .eraseToAnyPublisher()
    }

    func stopTracking() {
        cancelRequested = true
    }

    // MARK: Private functions

    private func startDetecting() -> AnyPublisher<[Participant], Error> {
        var frames = 1
        var participants: [Participant] = []
        var requestHandler = VNSequenceRequestHandler()

        return Future<[Participant], Error> { [weak self] promise in
            guard let self = self else {
                return
            }
            self.backgroundQueue.async {
                while true {
                    guard self.cancelRequested == false else {
                        promise(.failure(VideoliticError.videoProcessorService(.detectingCancelled)))
                        break
                    }

                    guard let frame = self.videoReader.nextFrame() else {
                        participants.forEach { $0.trackingRequest?.isLastFrame = true }
                        break
                    }

                    self.frame = frame
                    frames += 1

                    guard participants.count >= 1 else {
                        _ = self.faceComputingService.detectFacesAndCreateTrackers(for: frame, participants: participants, handler: requestHandler, trackObservation: nil, timestamp: frame.timestamp, orientation: self.videoReader.orientation)
                        .sink(receiveCompletion: { _ in }, receiveValue: { results in
                            participants = results.map { $0.0 }
                        })
                        continue
                    }
                    if frames.isMultiple(of: self.videoReader.refreshDetectionFrameInterval) {
                        for participant in participants {
                            guard let observation = (participant.trackingRequest?.results as? [VNDetectedObjectObservation])?.first else {
                                requestHandler = VNSequenceRequestHandler()
                                continue
                            }
                            _ = self.faceComputingService.detectFacesAndCreateTrackers(for: frame, participants: participants, handler: requestHandler, trackObservation: observation, timestamp: frame.timestamp, orientation: self.videoReader.orientation)
                        }
                    }

                    let trackingRequests = participants.compactMap { $0.trackingRequest }
                    do {
                        try requestHandler.perform(trackingRequests, on: frame.pixelBuffer, orientation: self.videoReader.orientation)
                    } catch {
                        promise(.failure(VideoliticError.videoProcessorService(.objectTrackingFailed)))
                    }
                }
                promise(.success(participants))
            }
        }
        .eraseToAnyPublisher()
    }
}
