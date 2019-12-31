//
//  FaceComputingService.swift
//  Videolitic
//
//  Created by Michał Rogowski on 03/01/2020.
//  Copyright © 2020 Michał Rogowski. All rights reserved.
//

import Combine
import UIKit
import Vision

protocol FaceComputingServiceInterface: class {

    func detectFacesAndCreateTrackers(for frame: VideoProcessingResult.Frame, participants: [Participant], handler: VNSequenceRequestHandler, trackObservation: VNDetectedObjectObservation?, timestamp: TimeInterval, orientation: CGImagePropertyOrientation) -> Future<[(Participant, FaceComputingService.Face)], Error>
}

final class FaceComputingService: FaceComputingServiceInterface {

    typealias Face = (image: CGImage, observation: VNFaceObservation)

    // MARK: Private properties

    private let ageModel: VNCoreMLModel
    private let emotionsModel: VNCoreMLModel
    private let genderModel: VNCoreMLModel
    private let raceModel: VNCoreMLModel

    // MARK: Initialisation

    init() throws {
        ageModel = try VNCoreMLModel(for: AgeModelUTK().model)
        emotionsModel = try VNCoreMLModel(for: Emotions().model)
        genderModel = try VNCoreMLModel(for: GenderNet().model)
        raceModel = try VNCoreMLModel(for: RaceModel().model)
    }

    // MARK: Public functions

    @discardableResult
    func detectFacesAndCreateTrackers(for frame: VideoProcessingResult.Frame, participants: [Participant], handler: VNSequenceRequestHandler, trackObservation: VNDetectedObjectObservation?, timestamp: TimeInterval, orientation: CGImagePropertyOrientation) -> Future<[(Participant, FaceComputingService.Face)], Error> {

        guard let imageFromFrame = UIImage(pixelBuffer: frame.pixelBuffer, orientation: orientation),
            let cgImage = imageFromFrame.cgImage else {
                return Future<[(Participant, Face)], Error> {
                    $0(.failure(VideoliticError.videoProcessorService(.cantGenerateUIImage)))
                }
        }

        return Future<[(Participant, Face)], Error> { promise in
            let detectRequest = cgImage.face.crop { images in
                switch images {
                case let .success(faces, _):
                    var results: [(Participant, Face)] = []
                    faces.forEach {
                        do {
                            let result = try self.addOrUpdate(face: $0, participants: participants, trackObservation: trackObservation, timestamp: frame.timestamp, orientation: orientation)
                            results.append(result)
                        } catch {
                            promise(.failure(error))
                        }
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

    // MARK: Private functions

    private func addOrUpdate(face: Face, participants: [Participant], trackObservation: VNDetectedObjectObservation?, timestamp: TimeInterval, orientation: CGImagePropertyOrientation) throws -> (Participant, Face) {
        let oldParticipant = participants.participant(for: trackObservation?.uuid ?? UUID())
        let participant = oldParticipant ?? Participant()
        participant.observations.append(face.observation)
        let image = UIImage(cgImage: face.image)
        let confidence = face.observation.confidence

        if (participant.sampleAvatar?.confidence ?? 0) < confidence {
            participant.sampleAvatar = (image, confidence)
        }

        let faceTrackingRequest = VNTrackObjectRequest(detectedObjectObservation: participant.trackingRequest?.inputObservation ?? face.observation)
        faceTrackingRequest.trackingLevel = participant.trackingLevel
        participant.trackingRequest = faceTrackingRequest

        try computeFace(for: participant, face: face, timestamp: timestamp, orientation: orientation)
        return (participant, face)
    }

    private func computeFace(for participant: Participant, face: Face, timestamp: TimeInterval, orientation: CGImagePropertyOrientation) throws {

        var coreMlRequests = [VNCoreMLRequest]()

        let genderRequest = VNCoreMLRequest(model: genderModel, completionHandler: { request, _ in
            guard let observations = request.results as? [VNClassificationObservation] else {
                return
            }
            guard let observation = observations.first else {
                return
            }
            participant.genderObservations.append(Participant.FrameObservation(observation, timestamp, face.observation.boundingBox))
        })

        let ageRequest = VNCoreMLRequest(model: ageModel, completionHandler: { request, _ in
            guard let observations = request.results as? [VNClassificationObservation] else {
                return
            }
            guard let observation = observations.first else {
                return
            }
            participant.ageObservations.append(Participant.FrameObservation(observation, timestamp, face.observation.boundingBox))
        })

        let raceRequest = VNCoreMLRequest(model: raceModel, completionHandler: { request, _ in
            guard let observations = request.results as? [VNClassificationObservation] else {
                return
            }
            guard let observation = observations.first else {
                return
            }
            participant.raceObservations.append(Participant.FrameObservation(observation, timestamp, face.observation.boundingBox))
        })

        let emotionsRequest = VNCoreMLRequest(model: emotionsModel) { request, _ in
            guard let observations = request.results as? [VNClassificationObservation] else {
                return
            }
            guard let observation = observations.first else {
                return
            }
            participant.emotionObservations.append(Participant.FrameObservation(observation, timestamp, face.observation.boundingBox))
        }

        coreMlRequests.append(genderRequest)
        coreMlRequests.append(ageRequest)
        coreMlRequests.append(raceRequest)
        coreMlRequests.append(emotionsRequest)

        let handler = VNImageRequestHandler(cgImage: face.image, orientation: orientation)
        try handler.perform(coreMlRequests)
    }
}
