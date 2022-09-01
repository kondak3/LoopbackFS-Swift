//
//  MountSystem.swift
//  LoopbackFS
//
//  Created by Konda Yadav on 01/09/22.
//  Copyright © 2022 KF Interactive GmbH. All rights reserved.
//

import Cocoa

class MountSystem: NSObject {

    // variables
    var rootPath: String!
    private lazy var loopFileSystem: LoopbackFS = {
        return LoopbackFS(rootPath: self.rootPath)
    }()
    private var userFileSystem: GMUserFileSystem?
    
    init(resourcePath: String) {
        self.rootPath = resourcePath
    }
    
    func createMountSystem() {
        
        let lastComponent = (self.rootPath as NSString).lastPathComponent
        let volumePath = "/Volumes/\(lastComponent)"
        
        // add options
        var options: [String] = ["native_xattr", "volname=\(lastComponent)", "local"]
        if let volumeIconPath = Bundle.main.path(forResource: "LoopbackFS", ofType: "icns") {
            options.insert("volicon=\(volumeIconPath)", at: 0)
        }

        userFileSystem = GMUserFileSystem(delegate: self.loopFileSystem, isThreadSafe: false)
        
        // Do not use the 'native_xattr' mount-time option unless the underlying
        // file system supports native extended attributes. Typically, the user
        // would be mounting an HFS+ directory through LoopbackFS, so we do want
        // this option in that case.
        userFileSystem!.mount(atPath: volumePath, withOptions: options)
    }
    
    deinit {
        print("MountSystem deinit..!")
    }
}
