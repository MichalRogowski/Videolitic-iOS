//
//  VideoProcessorService.swift
//  Videolitic
//
//  Created by Michał Rogowski on 29/11/2019.
//  Copyright © 2019 Michał Rogowski. All rights reserved.
//

import Accelerate
import AVFoundation
import Combine
import Photos
import Speech
import UIKit
import VideoToolbox
import Vision

typealias Face = (image: CGImage, observation: VNFaceObservation)
typealias MLResult = (value: String, confidence: String)

protocol VideoProcessorServiceInterface: class {

    func prepareTracking(for asset: AVAsset, toAudioNamed audioName: String) -> AnyPublisher<VideoReaderInterface.Frame?, Error>
    func startTracking() throws -> AnyPublisher<([SFTranscriptionSegment], [Participiant]), Error>
    func stopTracking()
}

final class VideoProcessorService: VideoProcessorServiceInterface {

    // MARK: Public properties

    @Published var frame: VideoReaderInterface.Frame?

    // MARK: Private properties

    private var cancelRequested = false

    private let audioProcessor: AudioProcessorServiceInterface
    private let videoReader: VideoReaderInterface
    private let backgroundQueue = DispatchQueue(label: "VideoProcessorServiceQueue")

    private let ageModel: VNCoreMLModel
    private let emotionsModel: VNCoreMLModel
    private let genderModel: VNCoreMLModel
    private let raceModel: VNCoreMLModel

    // MARK: Initialisation

    init(audioProcessor: AudioProcessorServiceInterface, videoReader: VideoReaderInterface) throws {
        self.audioProcessor = audioProcessor
        self.videoReader = videoReader
        self.ageModel = try VNCoreMLModel(for: AgeModelUTK().model)
        self.emotionsModel = try VNCoreMLModel(for: Emotions().model)
        self.genderModel = try VNCoreMLModel(for: GenderNet().model)
        self.raceModel = try VNCoreMLModel(for: RaceModel().model)
    }

    // MARK: Public functions

    func prepareTracking(for asset: AVAsset, toAudioNamed audioName: String) -> AnyPublisher<VideoReaderInterface.Frame?, Error> {
        audioProcessor
            .convert(video: asset, toAudioNamed: audioName)
            .flatMap { status in
                return Future<VideoReaderInterface.Frame?, Error> { promise in
                    if status == .completed {
                        promise(.success(self.videoReader.nextFrame()))
                    } else {
                        promise(.failure(VideoliticError.videoProcessorService(.cantConvertToAudio)))
                    }
                }
            }
            .eraseToAnyPublisher()
    }

    func startTracking() -> AnyPublisher<([SFTranscriptionSegment], [Participiant]), Error> {
        guard videoReader.nextFrame() != nil else {
            return Future<([SFTranscriptionSegment], [Participiant]), Error> {
                $0(.failure(VideoliticError.videoProcessorService(.firstFrameReadFailed)))
            }
            .eraseToAnyPublisher()
        }

        cancelRequested = false

        return Publishers.CombineLatest(audioProcessor.recognizeSpeechPublisher, startDetecting())
            .eraseToAnyPublisher()
    }

    func stopTracking() {
        cancelRequested = true
    }

    private func startDetecting() -> Future<[Participiant], Error> {
        var frames = 1
        var participiants: [Participiant] = []
        var requestHandler = VNSequenceRequestHandler()

        return Future<[Participiant], Error> { [weak self] promise in
            guard let self = self else {
                return
            }

            while true {
                guard self.cancelRequested == false else {
                    promise(.failure(VideoliticError.videoProcessorService(.detectingCancelled)))
                    break
                }

                guard let frame = self.videoReader.nextFrame() else {
                    participiants.forEach { $0.trackingRequest?.isLastFrame = true }
                    break
                }

                self.frame = frame
                frames += 1

                guard participiants.count >= 1 else {
                    _ = self.detectFacesAndCreateTrackers(for: frame, participiants: participiants, handler: requestHandler, timestamp: frame.timestamp)
                    .sink(receiveCompletion: { _ in }, receiveValue: { results in
                        participiants = results.map { $0.0 }
                    })
                    continue
                }
                if frames.isMultiple(of: self.videoReader.refreshDetectionFrameInterval) {
                    for participiant in participiants {
                        guard let observation = (participiant.trackingRequest?.results as? [VNDetectedObjectObservation])?.first else {
                            requestHandler = VNSequenceRequestHandler()
                            continue
                        }
                        _ = self.detectFacesAndCreateTrackers(for: frame, participiants: participiants, handler: requestHandler, trackObservation: observation, timestamp: frame.timestamp)
                    }
                }

                let trackingRequests = participiants.compactMap { $0.trackingRequest }
                do {
                    try requestHandler.perform(trackingRequests, on: frame.pixelBuffer, orientation: self.videoReader.orientation)
                } catch {
                    promise(.failure(VideoliticError.videoProcessorService(.objectTrackingFailed)))
                }
            }
            promise(.success(participiants))
        }
    }

    // MARK: Private functions

    @discardableResult
    private func detectFacesAndCreateTrackers(for frame: VideoReaderInterface.Frame, participiants: [Participiant], handler: VNSequenceRequestHandler, trackObservation: VNDetectedObjectObservation? = nil, timestamp: TimeInterval) -> Future<[(Participiant, Face)], Error> {

        guard let imageFromFrame = UIImage(pixelBuffer: frame.pixelBuffer, orientation: videoReader.orientation),
            let cgImage = imageFromFrame.cgImage else {
                return Future<[(Participiant, Face)], Error> {
                    $0(.failure(VideoliticError.videoProcessorService(.cantGenerateUIImage)))
                }
        }

        return Future<[(Participiant, Face)], Error> { promise in
            let detectRequest = cgImage.face.crop { images in
                switch images {
                case let .success(faces, _):
                    var results: [(Participiant, Face)] = []
                    faces.forEach {
                        let result = self.addOrUpdate(face: $0, participiants: participiants, trackObservation: trackObservation, timestamp: frame.timestamp)
                        results.append(result)
                    }
                    promise(.success(results))
                case .notFound:
                    promise(.success([]))
                case let .failure(error):
                    promise(.failure(error))
                }
            }
            detectRequest.preferBackgroundProcessing = true

            //https://stackoverflow.com/a/52201244/2467179
            if let regionOfIntrest = trackObservation?.boundingBox {
                let x = max((regionOfIntrest.origin.x - 0.1), 0)
                let y = max((regionOfIntrest.origin.y - 0.1), 0)

                let width = min((regionOfIntrest.size.width + 0.2), (1 - x))
                let height = min((regionOfIntrest.size.height + 0.2), (1 - y))

                detectRequest.regionOfInterest = CGRect(x: x, y: y, width: width, height: height)
            }
            do {
                try handler.perform([detectRequest], on: frame.pixelBuffer)
            } catch {
                promise(.failure(error))
            }
        }
    }

    private func addOrUpdate(face: Face, participiants: [Participiant], trackObservation: VNDetectedObjectObservation?, timestamp: TimeInterval) -> (Participiant, Face) {
        let oldParticipant = participiants.participant(for: trackObservation?.uuid ?? UUID())
        let participiant = oldParticipant ?? Participiant()
        participiant.observations.append(face.observation)
        let image = UIImage(cgImage: face.image)
        let confidence = face.observation.confidence

        if (participiant.sampleAvatar?.confidence ?? 0) < confidence {
            participiant.sampleAvatar = (image, confidence)
        }

        let faceTrackingRequest = VNTrackObjectRequest(detectedObjectObservation: participiant.trackingRequest?.inputObservation ?? face.observation)
        faceTrackingRequest.trackingLevel = participiant.trackingLevel
        participiant.trackingRequest = faceTrackingRequest

        do {
            try self.computeFace(for: participiant, face: face, timestamp: timestamp)
        } catch {
            debugPrint("error = \(error)")
        }
        return (participiant, face)
    }

    private func computeFace(for participiant: Participiant, face: Face, timestamp: TimeInterval) throws {

        var coreMlRequests = [VNCoreMLRequest]()

        let genderRequest = VNCoreMLRequest(model: genderModel, completionHandler: { request, _ in
            guard let observations = request.results as? [VNClassificationObservation] else {
                return
            }
            guard let observation = observations.first else {
                return
            }
            participiant.genderObservations.append(Participiant.FrameObservation(observation, timestamp, face.observation.boundingBox))
        })

        let ageRequest = VNCoreMLRequest(model: ageModel, completionHandler: { request, _ in
            guard let observations = request.results as? [VNClassificationObservation] else {
                return
            }
            guard let observation = observations.first else {
                return
            }
            participiant.ageObservations.append(Participiant.FrameObservation(observation, timestamp, face.observation.boundingBox))
        })

        let raceRequest = VNCoreMLRequest(model: raceModel, completionHandler: { request, _ in
            guard let observations = request.results as? [VNClassificationObservation] else {
                return
            }
            guard let observation = observations.first else {
                return
            }
            participiant.raceObservations.append(Participiant.FrameObservation(observation, timestamp, face.observation.boundingBox))
        })

        let emotionsRequest = VNCoreMLRequest(model: emotionsModel) { request, _ in
            guard let observations = request.results as? [VNClassificationObservation] else {
                return
            }
            guard let observation = observations.first else {
                return
            }
            participiant.emotionObservations.append(Participiant.FrameObservation(observation, timestamp, face.observation.boundingBox))
        }

        coreMlRequests.append(genderRequest)
        coreMlRequests.append(ageRequest)
        coreMlRequests.append(raceRequest)
        coreMlRequests.append(emotionsRequest)

        let handler = VNImageRequestHandler(cgImage: face.image, orientation: videoReader.orientation)
        try handler.perform(coreMlRequests)
    }
}
