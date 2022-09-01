//
//  AppDelegate.swift
//  LoopbackFS
//
//  Created by Gunnar Herzog on 27/01/2017.
//  Copyright © 2017 KF Interactive GmbH. All rights reserved.
//  Copyright © 2019-2020 Benjamin Fleischer. All rights reserved.
//

import Cocoa

//let loopbackMountPath = "/Volumes/loop"

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!

    private var notificationObservers: [NSObjectProtocol] = []
    /*private var rootPath: String!
    private lazy var loopFileSystem: LoopbackFS = {
        return LoopbackFS(rootPath: self.rootPath)
    }()

    private var userFileSystem: GMUserFileSystem?*/
    
    private var indexPath: Int = 0
    private var folderPathsArray: [String] = []
    private var mountsArray: [MountSystem] = []
    

    func applicationDidFinishLaunching(_ aNotification: Notification) {        
        /*let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = URL(fileURLWithPath: "/tmp")
        let returnValue = panel.runModal()

        guard returnValue.rawValue != NSFileHandlingPanelCancelButton, let rootPath = panel.urls.first?.path else { exit(0) }

        addNotifications()

        self.rootPath = rootPath

        var options: [String] = ["native_xattr", "volname=LoopbackFS"]

        if let volumeIconPath = Bundle.main.path(forResource: "LoopbackFS", ofType: "icns") {
            options.insert("volicon=\(volumeIconPath)", at: 0)
        }

        userFileSystem = GMUserFileSystem(delegate: self.loopFileSystem, isThreadSafe: false)
        
        // Do not use the 'native_xattr' mount-time option unless the underlying
        // file system supports native extended attributes. Typically, the user
        // would be mounting an HFS+ directory through LoopbackFS, so we do want
        // this option in that case.
        userFileSystem!.mount(atPath: loopbackMountPath, withOptions: options)*/
        
        addNotifications()
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.createFolders()
            self?.continueMounts()
        }
    }

    func addNotifications() {
        let mountObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name(kGMUserFileSystemDidMount), object: nil, queue: nil) { [weak self] notification in
            
            // get mount path
            guard let userInfo = notification.userInfo, let mountPath = userInfo["mountPath"] as? String else { return }
            print("Got didMount notification: \(mountPath)")

            let parentPath = (mountPath as NSString).deletingLastPathComponent
            NSWorkspace.shared.selectFile(mountPath, inFileViewerRootedAtPath: parentPath)
            self?.continueMounts()
            
            
            /*let parentPath = (loopbackMountPath as NSString).deletingLastPathComponent
            NSWorkspace.shared.selectFile(loopbackMountPath, inFileViewerRootedAtPath: parentPath)*/
        }

        let failedObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name(kGMUserFileSystemMountFailed), object: nil, queue: .main) { notification in
            print("Got mountFailed notification.")

            guard let userInfo = notification.userInfo, let error = userInfo[kGMUserFileSystemErrorKey] as? NSError else { return }
            print("kGMUserFileSystem Error: \(error), userInfo=\(error.userInfo)")
            
            /*let alert = NSAlert()
            alert.messageText = "Mount Failed"
            alert.informativeText = error.localizedDescription
            alert.runModal()

            NSApplication.shared.terminate(nil)*/
        }

        let unmountObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name(kGMUserFileSystemDidUnmount), object: nil, queue: nil) { notification in
            
            // get mount path
            guard let userInfo = notification.userInfo, let mountPath = userInfo["mountPath"] as? String else { return }
            print("Got didUnmount notification: \(mountPath)")

            DispatchQueue.main.async {
                let componentPath = (mountPath as NSString).lastPathComponent
                for i in 0 ..< self.mountsArray.count {
                    if self.mountsArray[i].rootPath.contains(componentPath) {
                        self.mountsArray.remove(at: i)
                        break
                    }
                }
            }
            
            
           /* DispatchQueue.main.async {
                NSApplication.shared.terminate(nil)
            }*/
        }

        self.notificationObservers = [mountObserver, failedObserver, unmountObserver]
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        notificationObservers.forEach {
            NotificationCenter.default.removeObserver($0)
        }
        notificationObservers.removeAll()

        /*if let userFileSystem = userFileSystem {
            userFileSystem.unmount()
        }*/
        return .terminateNow
    }
}

extension AppDelegate {
    
    // MARK: - Helpers
    func createFolders() {
        
        // resource paths
        let resourcePath: String? = Bundle.main.resourcePath
        var folderName: Int = 2020
        for _ in 0 ..< 10 {
            
            // increase folder names
            folderName = folderName + 1
            
            // create foler under resources
            let directoryPath = (resourcePath! as NSString).appendingPathComponent("\(folderName)")
            do {
                try FileManager.default.createDirectory(atPath: directoryPath, withIntermediateDirectories: true, attributes: nil)
                self.folderPathsArray.append(directoryPath)
            } catch {
                print("Folder creation error: \(error.localizedDescription)")
            }
        }
        print("Folders paths: \(self.folderPathsArray)")
    }
    
    func continueMounts() {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 10)
        { [weak self] in
            
            guard let strongSelf = self else { return }
            if strongSelf.indexPath < strongSelf.folderPathsArray.count {
                
                // create mount system
                var mountObj: MountSystem? = MountSystem.init(resourcePath: strongSelf.folderPathsArray[strongSelf.indexPath])
                strongSelf.mountsArray.append(mountObj!)
                mountObj = nil
                
                let counts = strongSelf.mountsArray.count
                strongSelf.mountsArray[counts-1].createMountSystem()
                strongSelf.indexPath = strongSelf.indexPath + 1
            } else {
                print("All mounts completed..!")
            }
        }
    }
    
}
