//
//  VideoProcessingResult.swift
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

public struct VideoProcessingResult {

    public typealias Frame = (pixelBuffer: CVPixelBuffer, timestamp: TimeInterval)
    
    typealias EmotionPerParticipant = (UUID, [Participant.FrameObservation])

    // MARK: Public properties

    /// ID of VideoProcessingResult
    let uuid = UUID().uuidString
    /// Participants taking part in a video
    public private(set) var participants: [VideoParticipant] = []
    /// Transcription with emotions
    public private(set) var results: [SpeechResultWithEmotion] = []
    /// Video orientation to map bounding boxes in right direction
    public let videoOrientation: UInt32
    /// Video asset URL
    public let videoURL: URL?
    /// Audio asset URL
    public let audioURL: URL

    // MARK: Private properties

    private let pauseBetweenSentences: TimeInterval = 0.2
}

extension VideoProcessingResult {

    // MARK: Initialisation

    init(audioURL: URL, orientation: CGImagePropertyOrientation, participants: [Participant], transcriptionSegments: [SFTranscriptionSegment], videoURL: URL?) {
        self.audioURL = audioURL
        self.videoURL = videoURL
        self.videoOrientation = orientation.rawValue
        self.participants = participants.compactMap { VideoParticipant(participant: $0) }

        results = transcriptionSegments.enumerated().map { index, segment -> SpeechResultWithEmotion in

            let emotionsPerParticipiant: [EmotionPerParticipant]
            let isEndOfSentence: Bool
            if transcriptionSegments.count <= index + 1 {
                emotionsPerParticipiant = participants.compactMap { ($0.uuid, $0.emotionObservations.filter { $0.timestamp >= segment.timestamp }) }
                isEndOfSentence = true
            } else {
                let nextSegment = transcriptionSegments[index + 1]
                emotionsPerParticipiant = participants.compactMap { ($0.uuid, $0.emotionObservations.filter { $0.timestamp >= segment.timestamp && $0.timestamp < nextSegment.timestamp }) }

                isEndOfSentence = (nextSegment.timestamp - (segment.timestamp + segment.duration)) > pauseBetweenSentences
            }

            return SpeechResultWithEmotion(emotions: emotionsPerParticipiant, segment: segment, isEndOfSentence: isEndOfSentence)
        }
    }
}
