//
//  AppDelegate.swift
//  Videolitic
//
//  Created by Michał Rogowski on 17/11/2019.
//  Copyright © 2019 Michał Rogowski. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

//    var sut2: VideoProcessorService!
//    var cancellabels: [AnyCancellable] = []
    // swiftlint:disable discouraged_optional_collection
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
//        do {
//            let bundle = Bundle(for: AudioProcessorService.self)
//            let url = bundle.url(forResource: "trump_clintoon", withExtension: "mov")!
//            let asset = AVAsset(url: url)
//            let audioName = UUID().uuidString
//            let audioURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(audioName).m4a")
//            let videoReader = try VideoReader(videoAsset: asset)
//            let audioProcessor = AudioProcessorService(audioURL: audioURL, speechRecognizer: SpeechRecognizer(defaultTaskHint: .dictation))
//
//            sut2 = try VideoProcessorService(audioProcessor: audioProcessor, videoReader: videoReader)
//
//            let cancelable = audioProcessor
//                .authorizeIfNeeded()
//                .eraseToAnyPublisher()
//                .flatMap { _ in self.sut2.prepareTracking(for: asset, toAudioNamed: audioName) }
//                .flatMap { _ in self.sut2.startTracking() }
//                .receive(on: RunLoop.main)
//                .sink(receiveCompletion: { completion in
//                    print("completion = \(completion)")
//                }) { transcription, participiants in
//                    print("transc = \(transcription)")
//                    print("participiants = \(participiants)")
//                }
//            cancellabels.append(cancelable)
//        } catch {
//            print("error = \(error.localizedDescription)")
//        }
        return true
    }
    // swiftlint:enable discouraged_optional_collection

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called
        // shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}
