//
//  Participiant.swift
//  Videolitic
//
//  Created by Michał Rogowski on 30/11/2019.
//  Copyright © 2019 Michał Rogowski. All rights reserved.
//

import AVFoundation
import UIKit
import Vision

class Participiant {
    typealias FrameObservation = (observation: VNClassificationObservation, timestamp: TimeInterval, boundingBox: CGRect)

    let uuid = UUID()
    let trackingLevel: VNRequestTrackingLevel = .accurate
    var observations: [VNFaceObservation] = []
    var ageObservations: [FrameObservation] = []
    var raceObservations: [FrameObservation] = []
    var genderObservations: [FrameObservation] = []
    var emotionObservations: [FrameObservation] = []
    var sampleAvatar: (image: UIImage, confidence: Float)?

    var trackingRequest: VNTrackObjectRequest?
}

extension Array where Element: Participiant {
    func find(for observation: VNFaceObservation) -> Participiant? {
        var boundingBoxes: [CGRect] = []
        for element in self {
            boundingBoxes.append(contentsOf: element.observations.compactMap { $0.boundingBox })
            if let observation = (element.trackingRequest?.results as? [VNDetectedObjectObservation])?.first {
                boundingBoxes.append(observation.boundingBox)
            }
        }
        boundingBoxes.forEach { print("old = \($0)") }
        return nil
    }

    func participant(for uuid: UUID) -> Participiant? {
        return first(where: { ((($0.trackingRequest?.results as? [VNDetectedObjectObservation])?.contains { $0.uuid == uuid }) != nil) })
    }
}
