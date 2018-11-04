//
//  GameViewController.swift
//  ViewRotMac
//
//  Created by kazunbu on 2018/09/27.
//  Copyright © 2018 kazunbu. All rights reserved.
//

import SceneKit
import QuartzCore

// thanks to: https://stackoverflow.com/questions/24200888/any-way-to-replace-characters-on-swift-string
extension String
{
    func replace(target: String, withString: String) -> String
    {
        return self.replacingOccurrences(of: target, with: withString, options: NSString.CompareOptions.literal, range: nil)
    }
}

class GameViewController: NSViewController {
    var documentList : [SCNScene] = []
    var documentIdx : Int = 0
    var scn = SCNView()
    var isload: Bool = false
    
    private func changeImage() {
        isload = false
        if(self.documentIdx < 0) {
            self.documentIdx = 0
        }
        if(self.documentList.count <= 0) {
            return
        }
        if(self.documentList.count <= self.documentIdx) {
            self.documentIdx = self.documentList.count - 1
            loadsImages()
            return
        }
        let screenWidth:CGFloat = self.view.frame.width
        let screenHeight:CGFloat = self.view.frame.height
        scn.frame = CGRect(x: 0, y: 0, width: CGFloat(screenWidth), height: screenHeight)
        scn.scene = self.documentList[self.documentIdx]
        // thanks to : https://stackoverflow.com/questions/10938223/how-can-i-create-an-cabasicanimation-for-multiple-properties
        let groupAnimation = CAAnimationGroup()
        groupAnimation.duration = 3
        let spin = CABasicAnimation(keyPath: "transform.rotation")
        spin.fromValue = NSValue(scnVector4: SCNVector4(x: 0, y: 1, z: 0, w: CGFloat(-Float.pi / 8.0)))
        spin.toValue   = NSValue(scnVector4: SCNVector4(x: 0, y: 1, z: 0, w: CGFloat( Float.pi / 8.0)))
        spin.duration  = 3
        let trans = CABasicAnimation(keyPath: "translation.x")
        trans.fromValue = sin(CGFloat(-Float.pi / 8.0))
        trans.toValue   = sin(CGFloat( Float.pi / 8.0))
        trans.duration  = 3
        groupAnimation.animations   = [spin, trans]
        groupAnimation.duration     = 3
        groupAnimation.autoreverses = true
        groupAnimation.repeatCount  = .infinity
        scn.scene?.rootNode.addAnimation(groupAnimation, forKey: "spin around")
        isload = true
        return
    }
    
    private func loadsImages() {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = true
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = true
        openPanel.directoryURL = URL(fileURLWithPath: "\(NSHomeDirectory())")
        openPanel.allowedFileTypes = ["scn"]
        let i = openPanel.runModal()
        if(i == NSApplication.ModalResponse.OK) {
            self.documentList = []
            do {
                try openPanel.urls.forEach({ (url) in
                    self.documentList.append(try SCNScene(url: url))
                })
            } catch {
                return
            }
            self.documentIdx = 0;
            self.changeImage()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let screenWidth:CGFloat = self.view.frame.width
        let screenHeight:CGFloat = self.view.frame.height
        scn.frame = CGRect(x: 0, y: 0, width: CGFloat(screenWidth), height: screenHeight)
        
        scn = SCNView(frame: CGRect(x: 0, y: 0, width: CGFloat(screenWidth), height: screenHeight))
        self.view.addSubview(scn)
        
        // configure the view
        scn.backgroundColor = NSColor.black
        
        // Add a click gesture recognizer
        let clickGesture = NSClickGestureRecognizer(target: self, action: #selector(handleClick(_:)))
        var gestureRecognizers = scn.gestureRecognizers
        gestureRecognizers.insert(clickGesture, at: 0)
        scn.gestureRecognizers = gestureRecognizers
        
        // thanks to https://joyplot.com/documents/2018/06/25/swift-nswindow-resize/
        NotificationCenter.default.addObserver(self, selector: #selector(self.resized),
                                               name: NSWindow.didResizeNotification, object: nil)
    }
    
    @objc func resized() {
        if(isload) {
            self.changeImage()
        }
    }
    
    @objc
    func handleClick(_ gestureRecognizer: NSGestureRecognizer) {
        // retrieve the SCNView
        let scnView = self.view as! SCNView
        
        // check what nodes are clicked
        let loc = gestureRecognizer.location(in: scnView)
        if(self.documentList.count <= 0) {
            self.loadsImages()
        } else {
            let screenWidth:CGFloat = self.view.frame.width
            if(loc.x < screenWidth / 2) {
                self.documentIdx -= 1
            } else {
                self.documentIdx += 1
            }
            self.changeImage()
        }
    }
}
