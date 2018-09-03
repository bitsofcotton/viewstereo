
//
//  GameViewController.swift
//  ViewVR
//
//  Created by kazunobu on 2018/07/13.
//  Copyright © 2018年 kazunobu. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit
import CoreMotion
import FileBrowser
import Zip

// thanks to: https://stackoverflow.com/questions/24200888/any-way-to-replace-characters-on-swift-string
extension String
{
    func replace(target: String, withString: String) -> String
    {
        return self.replacingOccurrences(of: target, with: withString, options: NSString.CompareOptions.literal, range: nil)
    }
}

class GameViewController: UIViewController {
    let documentsDirectory = FileManager.default.temporaryDirectory
    var documentList : [String] = []
    var documentIdx : Int = 0
    
    let manager = CMMotionManager()
    var knocked : Bool = false
    let motionUpdateInterval : Double = 0.05
    var knockReset : Double = 2.0
    
    var scn = SCNView()
    
    private func changeImage() {
        if(self.documentIdx < 0) {
            self.documentIdx = 0
        }
        if(self.documentList.count <= 0 || self.documentList.count <= self.documentIdx) {
            loadsImages()
            return
        }
        do {
            let screenWidth:CGFloat = self.view.frame.width
            let screenHeight:CGFloat = self.view.frame.height
            scn.frame = CGRect(x: 0, y: 0, width: CGFloat(screenWidth), height: screenHeight)
            let scene = try SCNScene(url: URL(fileURLWithPath: self.documentsDirectory.path + "/" + self.documentList[self.documentIdx]))
            let ambientLightNode = SCNNode()
            ambientLightNode.light = SCNLight()
            ambientLightNode.light!.type = .ambient
            ambientLightNode.light!.color = UIColor.white
            scene.rootNode.addChildNode(ambientLightNode)
            scn.scene = scene
            let spin = CABasicAnimation(keyPath: "rotation")
            spin.fromValue = NSValue(scnVector4: SCNVector4(x: 0, y: 1, z: 0, w: -Float.pi / 8.0))
            spin.toValue = NSValue(scnVector4: SCNVector4(x: 0, y: 1, z: 0, w: Float.pi / 8.0))
            spin.duration = 3
            spin.autoreverses = true
            spin.repeatCount = .infinity
            scn.scene?.rootNode.addAnimation(spin, forKey: "spin around")
            UIApplication.shared.isIdleTimerDisabled = true
        } catch {
            return
        }
        return
    }
    
    private func loadsImages() {
        let fileBrowser = FileBrowser()
        present(fileBrowser, animated: true, completion: nil)
        let cself = self
        fileBrowser.didSelectFile = { (file: FBFile) -> Void in
            do {
                let manager = FileManager()
                do {
                    let list = try manager.contentsOfDirectory(atPath: cself.documentsDirectory.path)
                    for path in list {
                        try manager.removeItem(atPath: cself.documentsDirectory.path + "/" + path)
                    }
                } catch {
                    
                }
                try Zip.unzipFile(file.filePath, destination: cself.documentsDirectory, overwrite: true, password: "", progress: { (progress) -> () in
                    
                })
                cself.documentList = []
                cself.documentIdx = 0
                let rawarray = try manager.contentsOfDirectory(atPath: cself.documentsDirectory.path)
                for raw in rawarray {
                    if(NSString(string: raw).pathExtension == "scn" && raw.suffix(5).contains("L.scn")) {
                        cself.documentList.insert(raw, at: cself.documentList.count)
                    }
                }
            } catch {
                let alert: UIAlertController = UIAlertController(title: "Some error.", message: "Some error while reading file.", preferredStyle:  UIAlertControllerStyle.alert)
                let defaultAction: UIAlertAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default)
                alert.addAction(defaultAction)
                cself.present(alert, animated: true, completion: nil)
            }
            cself.documentList.sort()
            cself.changeImage()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let screenWidth:CGFloat = self.view.frame.width
        let screenHeight:CGFloat = self.view.frame.height
        scn.frame = CGRect(x: 0, y: 0, width: CGFloat(screenWidth), height: screenHeight)

        scn = SCNView(frame: CGRect(x: 0, y: 0, width: CGFloat(screenWidth), height: screenHeight))
        self.view.addSubview(scn)
        scn.addGestureRecognizer(UITapGestureRecognizer(
            target: self, action: #selector(self.tap(sender:))))
        // Thanks to :
        // https://stackoverflow.com/questions/30619778/swift-coremotion-detect-tap-or-knock-on-device-while-in-background
        if manager.isDeviceMotionAvailable {
            manager.deviceMotionUpdateInterval = motionUpdateInterval
            let cself = self
            manager.startDeviceMotionUpdates(to: OperationQueue.current!, withHandler: { (data, error) in
                if (pow((data?.userAcceleration.x)!, 2.0) + pow((data?.userAcceleration.y)!, 2.0) + pow((data?.userAcceleration.y)!, 2.0) > pow(Double(0.7), 2.0)) {
                    if cself.knocked == false {
                        cself.knocked = true
                    } else {
                        cself.knocked = false
                        cself.knockReset = 2.0
                        cself.documentIdx += 1
                        cself.changeImage()
                    }
                }
                if (cself.knocked) && (cself.knockReset >= 0.0) {
                    cself.knockReset = cself.knockReset - cself.motionUpdateInterval
                } else if cself.knocked == true {
                    cself.knocked = false
                    cself.knockReset = 2.0
                }
            })
        }
    }
    
    @objc func tap(sender: UITapGestureRecognizer) {
        if sender.state == .ended {
            if(self.documentList.count <= 0) {
                self.loadsImages()
            } else {
                let screenWidth:CGFloat = self.view.frame.width
                let loc = sender.location(in: self.view)
                if(loc.x < screenWidth / 2) {
                    self.documentIdx -= 1
                } else {
                    self.documentIdx += 1
                }
                self.changeImage()
            }
        }
        return
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

}
