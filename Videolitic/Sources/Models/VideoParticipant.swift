//
//  VideoParticipant.swift
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

public struct VideoParticipant: Identifiable {

    /// Id of participant
    public let id: String
    /// Average age of all results
    public let age: Float
    /// The most common detected Gender
    public let gender: String
    /// Sample image of Participant
    public let sampleImage: Data?
    /// The most common detected race
    public let race: String
}

extension VideoParticipant {

    init(participant: Participant) {
        let races = participant.raceObservations
            .compactMap { $0.observation.identifier }
            .reduce(into: [:]) { $0[$1, default: 0] += 1 }
            .sorted { $0.1 > $1.1 }
        let genders = participant.genderObservations
            .compactMap { $0.observation.identifier }
            .reduce(into: [:]) { $0[$1, default: 0] += 1 }
            .sorted { $0.1 > $1.1 }

        id = participant.uuid.uuidString
        age = Float(participant.ageObservations
            .compactMap { Int($0.observation.identifier) }
            .reduce(0, +)) / Float(participant.ageObservations.count)
        race = races.first?.key ?? "Cannot specify race"
        gender = genders.first?.key ?? "Cannot specify gender"
        sampleImage = participant.sampleAvatar?.image.pngData()
    }
}
