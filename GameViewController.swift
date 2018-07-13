
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
    
    var scnL = SCNView()
    var scnR = SCNView()
    
    private func changeImage() {
        if(self.documentIdx < 0) {
            self.documentIdx = 0
        }
        if(self.documentList.count <= 0 || self.documentList.count <= self.documentIdx) {
            loadsImages()
            return
        }
        do {
            let sceneL = try SCNScene(url: URL(fileURLWithPath: self.documentsDirectory.path + "/" + self.documentList[self.documentIdx]))
            print((self.documentsDirectory.path + "/" + self.documentList[self.documentIdx]).replace(target: "L.scn", withString: "R.scn"))
            let sceneR = try SCNScene(url: URL(fileURLWithPath: (self.documentsDirectory.path + "/" + self.documentList[self.documentIdx]).replace(target: "L.scn", withString: "R.scn")))
            let ambientLightNodeL = SCNNode()
            let ambientLightNodeR = SCNNode()
            ambientLightNodeL.light = SCNLight()
            ambientLightNodeR.light = SCNLight()
            ambientLightNodeL.light!.type = .ambient
            ambientLightNodeR.light!.type = .ambient
            ambientLightNodeL.light!.color = UIColor.white
            ambientLightNodeR.light!.color = UIColor.white
            sceneL.rootNode.addChildNode(ambientLightNodeL)
            sceneR.rootNode.addChildNode(ambientLightNodeR)
            scnL.scene = sceneL
            scnR.scene = sceneR
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
            cself.changeImage()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let screenWidth:CGFloat = self.view.frame.width
        let screenHeight:CGFloat = self.view.frame.height
        scnL = SCNView(frame: CGRect(x: CGFloat(-screenWidth / 2 * 0.4), y: 0, width: CGFloat(screenWidth / 2 * 1.4), height: screenHeight))
        scnR = SCNView(frame: CGRect(x: screenWidth / 2, y: 0, width: CGFloat(screenWidth / 2 * 1.4), height: screenHeight))
        self.view.addSubview(scnL)
        self.view.addSubview(scnR)
        scnL.addGestureRecognizer(UITapGestureRecognizer(
            target: self, action: #selector(self.tapLeft(sender:))))
        scnR.addGestureRecognizer(UITapGestureRecognizer(
            target: self, action: #selector(self.tapRight(sender:))))
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
    
    @objc func tapLeft(sender: UITapGestureRecognizer) {
        documentIdx -= 1
        changeImage()
        return
    }
    
    @objc func tapRight(sender: UITapGestureRecognizer) {
        documentIdx += 1
        changeImage()
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
