//
//  PlayerView.swift
//  Videolitic-Example
//
//  Created by Michał Rogowski on 07/02/2020.
//  Copyright © 2020 Michał Rogowski. All rights reserved.
//

import AVFoundation
import SwiftUI
import UIKit
import Videolitic

struct PlayerView: UIViewRepresentable {

    @EnvironmentObject var viewModel: VideoResultViewModel

    let asset: AVAsset

    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<PlayerView>) {
    }

    func makeUIView(context: Context) -> UIView {
        PlayerUIView(asset: asset, viewModel: viewModel)
    }
}

class PlayerUIView: UIView {

    private var rectangles: [TrackingRectangle]
    private let playerLayer = AVPlayerLayer()
    private var size: CGRect = .zero
    init(asset: AVAsset, viewModel: VideoResultViewModel) {
        self.rectangles = viewModel.rectangles
        super.init(frame: .zero)

        playerLayer.addObserver(self, forKeyPath: #keyPath(AVPlayerLayer.videoRect), options: [.old, .new], context: nil)
        let player = AVPlayer(playerItem: AVPlayerItem(asset: asset))
        player.play()

        playerLayer.player = player
        layer.addSublayer(playerLayer)

        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] timer in
            self?.updateRectangles()
        }

        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            let speechTexts = viewModel.videoResult?.results ?? []
            let currentText = speechTexts.filter { ($0.textTimestamp + $0.duration) < (self?.playerLayer.player?.currentItem?.currentTime().seconds ?? 0) }
            guard let last = currentText.last else {
                return
            }
            self?.updateText(text: last)
        }
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {

        if keyPath == #keyPath(AVPlayerLayer.videoRect){
            if let size = change?[.newKey] as? CGRect {
                self.size = size
                updateRectangles()
            }
        }
    }

    private func updateRectangles() {
        guard size != .zero else {
            return
        }
        let rectangles = self.rectangles.filter { $0.timestamp <= (playerLayer.player?.currentItem?.currentTime().seconds ?? 0) }
        let myLayers = playerLayer.sublayers?.filter { $0.name == "FrameLane" }
        myLayers?.forEach { $0.removeFromSuperlayer() }
        for rectangle in rectangles {
            let layer = CAShapeLayer()
            let rect = CGRect(x: rectangle.topLeft.x * size.maxX, y: rectangle.topLeft.y * size.maxY, width: (rectangle.bottomRight.x - rectangle.topLeft.x) * size.maxX, height: (rectangle.bottomRight.y - rectangle.topLeft.y) * size.maxY)
            layer.path = UIBezierPath(rect: rect).cgPath
            layer.strokeColor = rectangle.color.cgColor
            layer.fillColor = UIColor.clear.cgColor
            layer.lineWidth = 3
            layer.name = "FrameLane"
            let textLayer = CATextLayer()
            textLayer.string = rectangle.emotion
            textLayer.fontSize = 10
            textLayer.frame = CGRect(x: rect.origin.x, y: rect.origin.y, width: rect.width, height: 11)
            textLayer.name = "FrameLane"
            textLayer.foregroundColor = UIColor.white.cgColor
            textLayer.backgroundColor = UIColor.black.withAlphaComponent(0.5).cgColor
            playerLayer.addSublayer(textLayer)
            playerLayer.addSublayer(layer)
        }
        self.rectangles.removeAll(where: { $0.timestamp <= (playerLayer.player?.currentItem?.currentTime().seconds ?? 0) })
    }

    private func updateText(text: SpeechResultWithEmotion) {
        let myLayers = playerLayer.sublayers?.filter { $0.name == "TextLayer" }
        myLayers?.forEach { $0.removeFromSuperlayer() }

        let textLayer = CATextLayer()
        textLayer.string = text.text
        textLayer.fontSize = 14
        textLayer.frame = CGRect(x: 0, y: size.origin.y + size.height - 15, width: size.width, height: 15)
        textLayer.name = "TextLayer"
        textLayer.alignmentMode = .center
        textLayer.foregroundColor = UIColor.white.cgColor
        textLayer.backgroundColor = UIColor.black.withAlphaComponent(0.5).cgColor
        playerLayer.addSublayer(textLayer)
    }


    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}
