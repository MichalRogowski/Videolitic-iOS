//
//  URL+Resources.swift
//  VideoliticTests
//
//  Created by Michał Rogowski on 29/11/2019.
//  Copyright © 2019 Michał Rogowski. All rights reserved.
//

import Foundation

extension URL {
    
    // MARK: Initialisation
    
    init(resource: String, extension ext: String) throws {
        
        let bundle = Bundle(for: AudioProcessorServiceTests.self)
        guard let url = bundle.url(forResource: resource, withExtension: ext) else {
            throw UnitTestErrors.cantCreateURL
        }
        self = url
    }
}
