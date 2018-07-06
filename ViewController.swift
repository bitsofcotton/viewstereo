//
//  ViewController.swift
//  ViewStereo
//
//  Created by kazunobu on 2018/06/26.
//  Copyright © 2018年 kazunobu. All rights reserved.
//

import UIKit
import CoreMotion
import FileBrowser
import Zip

class ViewController: UIViewController {
    let progressbar = UIProgressView()
    let imageView = UIImageView()
    let documentsDirectory = FileManager.default.temporaryDirectory
    var documentList : [String] = []
    var documentIdx : Int = 0
    
    let manager = CMMotionManager()
    var knocked : Bool = false
    let motionUpdateInterval : Double = 0.05
    var knockReset : Double = 2.0
    
    private func showImage() {
        if(self.documentIdx < 0) {
            self.documentIdx = 0
        }
        if(self.documentList.count <= 0) {
            return
        }
        self.documentIdx %= self.documentList.count
        let screenWidth:CGFloat = self.view.frame.width
        let screenHeight:CGFloat = self.view.frame.height
        do {
            self.imageView.image = UIImage(data: try Data(contentsOf: URL(fileURLWithPath: self.documentsDirectory.path + "/" + self.documentList[self.documentIdx])))
        } catch {
            return
        }
        self.imageView.center = CGPoint(x:screenWidth/2, y:screenHeight/2)
        self.imageView.frame = CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight)
        self.imageView.contentMode = UIViewContentMode.scaleAspectFit
        self.imageView.setNeedsLayout()
        self.progressbar.setProgress(Float(self.documentIdx) / Float(self.documentList.count), animated: false)
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    private func loadsImages() {
        let fileBrowser = FileBrowser()
        present(fileBrowser, animated: true, completion: nil)
        let cself = self
        cself.progressbar.setProgress(Float(0.0), animated: true)
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
                    cself.progressbar.setProgress(Float(progress), animated: true)
                })
                cself.documentList = try manager.contentsOfDirectory(atPath: cself.documentsDirectory.path)
                cself.documentIdx = 0
            } catch {
                let alert: UIAlertController = UIAlertController(title: "Some error.", message: "Some error while reading file.", preferredStyle:  UIAlertControllerStyle.alert)
                let defaultAction: UIAlertAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default)
                alert.addAction(defaultAction)
                cself.present(alert, animated: true, completion: nil)
            }
            cself.showImage()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.becomeFirstResponder()
        let screenWidth:CGFloat = self.view.frame.width
        let screenHeight:CGFloat = self.view.frame.height
        self.progressbar.frame = CGRect(x: 0, y: 0, width: screenWidth, height: 20)
        self.view.addSubview(progressbar)
        self.imageView.center = CGPoint(x:screenWidth/2, y:screenHeight/2)
        self.imageView.frame = CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight)
        self.imageView.contentMode = UIViewContentMode.scaleAspectFit
        self.view.self.addSubview(imageView)
        let gesture: UITapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(ViewController.tapped(sender:)))
        self.view.addGestureRecognizer(gesture)
        
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
                        cself.showImage()
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
    
    @objc func tapped(sender: UITapGestureRecognizer){
        if sender.state == .ended {
            if(self.documentList.count <= 0) {
                loadsImages()
            } else {
                let screenWidth:CGFloat = self.view.frame.width
                let loc = sender.location(in: self.view)
                if(loc.x < screenWidth / 2) {
                    self.documentIdx -= 1
                } else {
                    self.documentIdx += 1
                }
                self.showImage()
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var canBecomeFirstResponder: Bool {
        get {
            return true
        }
    }
    
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        if (motion == .motionShake || motion == .remoteControlNextTrack) {
            if(self.documentList.count <= 0) {
                self.loadsImages()
            }
        }
        return
    }
}
