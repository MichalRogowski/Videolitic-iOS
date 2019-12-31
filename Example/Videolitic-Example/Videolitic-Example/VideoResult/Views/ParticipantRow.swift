//
//  ParticipantRow.swift
//  Videolitic-Example
//
//  Created by Michał Rogowski on 07/01/2020.
//  Copyright © 2020 Michał Rogowski. All rights reserved.
//

import SwiftUI
import Videolitic

struct ParticipantRow: View {

    var participant: VideoParticipant

    var body: some View {
        HStack {
            Image(uiImage: UIImage(data: participant.sampleImage ?? Data()) ?? UIImage())
                .resizable()
                .frame(width: 50, height: 50)
            VStack {
                Spacer()
                Text("Age: \(participant.age)")
                Text("Gender: \(participant.gender)")
                Text("Race: \(participant.race)")
                Spacer()
            }
            Spacer()
        }
    }
}
