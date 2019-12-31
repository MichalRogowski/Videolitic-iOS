//
//  ResultsView.swift
//  Videolitic-Example
//
//  Created by Michał Rogowski on 07/01/2020.
//  Copyright © 2020 Michał Rogowski. All rights reserved.
//

import Combine
import SwiftUI
import Videolitic

enum PresentationMode: String {
    case participant
    case transcription
}

struct ResultsView: View {

    @EnvironmentObject var viewModel: VideoResultViewModel

    var body: some View {
        CorrectResultView()
            .alert(isPresented: $viewModel.showingAlert) {
                Alert(title: Text("Error occurred"), message: Text(viewModel.errorString ?? ""), dismissButton: .default(Text("Got it!")))
            }
    }
}


struct CorrectResultView: View {

    @EnvironmentObject var viewModel: VideoResultViewModel

    @State var selectedMode: PresentationMode = .participant

    var body: some View {
        NavigationView {
            GeometryReader { generalProxy in
                HStack {
                    PlayerView(asset: self.viewModel.asset)
                        .frame(width: generalProxy.size.width / 2)
                    DetailsView(mode: self.selectedMode)
                        .frame(width: generalProxy.size.width / 2)
                }
            }
            .navigationBarTitle("Videolitic Example", displayMode: .inline)
            .navigationBarItems(trailing:
                Picker("Numbers", selection: $selectedMode) {
                    Text("Participant").tag(PresentationMode.participant)
                    Text("Transcription").tag(PresentationMode.transcription)
                }
                .pickerStyle(SegmentedPickerStyle())
            )
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
