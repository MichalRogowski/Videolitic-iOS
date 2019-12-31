//
//  DetailsView.swift
//  Videolitic-Example
//
//  Created by Michał Rogowski on 08/02/2020.
//  Copyright © 2020 Michał Rogowski. All rights reserved.
//

import SwiftUI
import Videolitic

struct DetailsView: View {

    private let selectedMode: PresentationMode

    init(mode: PresentationMode) {
        self.selectedMode = mode
    }

    @ViewBuilder
    var body: some View {
        if selectedMode == .participant {
            ParticipantsView()
        } else {
            TranscriptionView()
        }
    }
}

struct ParticipantsView: View {

    @EnvironmentObject var viewModel: VideoResultViewModel

    private var participants: [VideoParticipant] {
        return viewModel.videoResult?.participants ?? []
    }

    var body: some View {
        List {
            Section {
                Text("Participants")
                    .fontWeight(.heavy)
            }
            Section {
                ForEach(self.participants) { ParticipantRow(participant: $0) }
            }
        }
    }
}

struct TranscriptionView: View {

    @EnvironmentObject var viewModel: VideoResultViewModel

    var body: some View {
        ScrollView {
            Text(viewModel.transcription)
        }
    }
}
