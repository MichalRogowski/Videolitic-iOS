//
//  VideoResultView.swift
//  Videolitic-Example
//
//  Created by Michał Rogowski on 06/01/2020.
//  Copyright © 2020 Michał Rogowski. All rights reserved.
//

import SwiftUI
import Videolitic

struct VideoResultView: View {

    @EnvironmentObject var viewModel: VideoResultViewModel

    @ViewBuilder
    var body: some View {
        if viewModel.isComputing {
            ComputingView()
        } else {
            ResultsView()
        }
    }
}
