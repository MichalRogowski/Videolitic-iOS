//
//  SpeechResultWithEmotion.swift
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
import Speech

public struct SpeechResultWithEmotion {

    /// Start of text
    public let textTimestamp: TimeInterval
    /// Duration of speaking text
    public let duration: TimeInterval
    /// Emotions of participants
    public let emotions: [Emotion]
    /// Text transcription
    public let text: String
    /// Confidence of transcription
    public let textConfidence: Float
}

extension SpeechResultWithEmotion {

    init(emotions: [VideoProcessingResult.EmotionPerParticipant], segment: SFTranscriptionSegment, isEndOfSentence: Bool) {
        textTimestamp = segment.timestamp
        duration = segment.duration
        text = segment.substring + (isEndOfSentence ? "." : "")
        textConfidence = segment.confidence
        self.emotions = emotions.map { emotion in
            emotion.1.map { Emotion(boundingBox: $0.boundingBox, observation: $0.observation, participantID: emotion.0.uuidString, timestamp: $0.timestamp) }
        }
        .reduce([], +)
    }
}
