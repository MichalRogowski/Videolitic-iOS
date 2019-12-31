//
//  Participant.swift
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
import UIKit
import Vision

final class Participant {

    typealias FrameObservation = (observation: VNClassificationObservation, timestamp: TimeInterval, boundingBox: CGRect)

    /// ID of Participant
    let uuid = UUID()
    /// Tracking level for tracking request
    let trackingLevel: VNRequestTrackingLevel = .accurate
    /// Detect face observation
    var observations: [VNFaceObservation] = []
    /// Age observations with boundingBox (Frame of face in video in this timestamp) and timebased
    var ageObservations: [FrameObservation] = []
    /// Race observations with boundingBox (Frame of face in video in this timestamp) and timebased
    var raceObservations: [FrameObservation] = []
    /// Gender observations with boundingBox (Frame of face in video in this timestamp) and timestamp
    var genderObservations: [FrameObservation] = []
    /// Emotions observations with boundingBox (Frame of face in video in this timestamp) and timestamp
    var emotionObservations: [FrameObservation] = []
    /// Avatar of Participant
    var sampleAvatar: (image: UIImage, confidence: Float)?

    var trackingRequest: VNTrackObjectRequest?
}

extension Array where Element == Participant {

    func participant(for uuid: UUID) -> Participant? {
        return first(where: { ((($0.trackingRequest?.results as? [VNDetectedObjectObservation])?.contains { $0.uuid == uuid }) != nil) })
    }
}
