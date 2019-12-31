//
//  Emotion.swift
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

import Foundation
import UIKit
import Vision

public struct Emotion {

    /// Position of face in the video
    public let boundingBox: CGRect
    /// Confidence of the Emotion
    public let confidence: Float
    /// Emotion identifier
    public let identifier: String
    /// Id of participant
    public let participantID: String
    /// Timestamp in the video of this emotion
    public let timestamp: TimeInterval
}

extension Emotion {

    init(boundingBox: CGRect, observation: VNClassificationObservation, participantID: String, timestamp: TimeInterval) {
        self.boundingBox = boundingBox
        self.confidence = observation.confidence * 100.0
        self.identifier = observation.identifier
        self.participantID = participantID
        self.timestamp = timestamp
    }
}
