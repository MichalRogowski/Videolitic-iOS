//
//  VideoResultViewModel.swift
//  Videolitic-Example
//
//  Created by Michał Rogowski on 06/01/2020.
//  Copyright © 2020 Michał Rogowski. All rights reserved.
//

import AVFoundation
import Combine
import SwiftUI
import Videolitic

class VideoResultViewModel: ObservableObject {

    @State var showingAlert = false

    @Published var asset: AVURLAsset!
    @Published var videoResult: VideoProcessingResult?
    @Published var transcription: String = ""
    @Published var currentText: String = ""
    @Published var isComputing: Bool = false
    @Published var errorString: String?
    @Published var rectangles: [TrackingRectangle] = []

    private var disposables = Set<AnyCancellable>()

    init() {
        guard let url = Bundle.url(forResource: "trump_clintoon", withExtension: "mov", subdirectory: nil, in: Bundle.main.bundleURL) else {
            fatalError("Video is not added in resources")
        }
        asset = AVURLAsset(url: url)
        computeTrumpClintonVideo()
        setupSubscriptions()
    }

    private func setupSubscriptions() {
        $videoResult
            .compactMap { $0 }
            .map { $0.results }
            .map { $0.map { $0.text } }
            .map { $0.joined(separator: " ") }
            .assign(to: \.transcription, on: self)
            .store(in: &disposables)

        $videoResult
            .compactMap { $0 }
            .map { self.computeRects(videoResult: $0) }
            .assign(to: \.rectangles, on: self)
            .store(in: &disposables)
    }

    private func computeTrumpClintonVideo() {
        isComputing = true
        do {
            let videoliticResult = try VideoliticService.compute(video: asset)
            
            videoliticResult.result
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { [weak self] completion in
                    guard let self = self else {
                        return
                    }
                    defer {
                        self.isComputing = false
                    }
                    switch completion {
                    case let .failure(error):
                        self.errorString = error.localizedDescription
                    case .finished:
                        break
                    }
                    }, receiveValue: { [weak self] result in
                        self?.videoResult = result
                    })
                .store(in: &disposables)


            //WE DO NOT NEED FRAMES, Only for testing purposes
//            videoliticResult.currentFrame
//                .compactMap { $0 }
//                .print()
//                .reduce([VideoProcessingResult.Frame](), { $0 + [$1] })
//                .assign(to: \.frames, on: self)
//                .store(in: &disposables)

        } catch {
            showingAlert = true
            errorString = error.localizedDescription
        }
    }

    private func computeRects(videoResult: VideoProcessingResult) -> [TrackingRectangle] {
        let emotions = videoResult.results.reduce(into: [Emotion](), { $0 += $1.emotions }).sorted(by: { $0.timestamp < $1.timestamp })
        return emotions.compactMap { emotion in
            let participantIndex = videoResult.participants.firstIndex(where: { $0.id == emotion.participantID }) ?? 0
            return TrackingRectangle(cgRect: emotion.boundingBox, color: .red, name: "Participant \(Int(participantIndex))", emotion: emotion.identifier, timestamp: emotion.timestamp)
        }
    }
}

struct TrackingRectangle {
    var topLeft: CGPoint
    var topRight: CGPoint
    var bottomLeft: CGPoint
    var bottomRight: CGPoint
    var color: UIColor
    var name: String
    var emotion: String
    var timestamp: TimeInterval

    var cornerPoints: [CGPoint] {
        return [topLeft, topRight, bottomRight, bottomLeft]
    }

    init(cgRect: CGRect, color: UIColor, name: String, emotion: String, timestamp: TimeInterval) {
        topLeft = CGPoint(x: cgRect.minX, y: cgRect.maxY)
        topRight = CGPoint(x: cgRect.maxX, y: cgRect.maxY)
        bottomLeft = CGPoint(x: cgRect.minX, y: cgRect.minY)
        bottomRight = CGPoint(x: cgRect.maxX, y: cgRect.minY)
        self.color = color
        self.name = name
        self.emotion = emotion
        self.timestamp = timestamp
    }
}
