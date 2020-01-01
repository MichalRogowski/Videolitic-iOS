//
//  FileManager+ClearTemp.swift
//  VideoliticTests
//
//  Created by Michał Rogowski on 30/11/2019.
//  Copyright © 2019 Michał Rogowski. All rights reserved.
//

import AVFoundation

extension FileManager {
    func clearTmpDirectory() throws {
        do {
            let tmpDirURL = FileManager.default.temporaryDirectory
            let tmpDirectory = try contentsOfDirectory(atPath: tmpDirURL.path)
            try tmpDirectory.forEach { file in
                let fileUrl = tmpDirURL.appendingPathComponent(file)
                try removeItem(atPath: fileUrl.path)
            }
        } catch {
           throw error
        }
    }
}
