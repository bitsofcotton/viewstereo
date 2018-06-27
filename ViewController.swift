//
//  ViewController.swift
//  ViewStereo
//
//  Created by kazunobu on 2018/06/26.
//  Copyright © 2018年 kazunobu. All rights reserved.
//

import UIKit
import FileBrowser
import Zip

class ViewController: UIViewController {
    let progressbar = UIProgressView()
    let imageView = UIImageView()
    let documentsDirectory = FileManager.default.temporaryDirectory
    var documentList : [String] = []
    var documentIdx : Int = 0
    
    private func showImage() {
        if(self.documentIdx < 0) {
            self.documentIdx = 0
        }
        if(self.documentList.count <= self.documentIdx) {
            self.documentIdx = self.documentList.count - 1
        }
        if(self.documentList.count <= 0) {
            return
        }
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
    }
    
    @objc func tapped(sender: UITapGestureRecognizer){
        if sender.state == .ended {
            let screenWidth:CGFloat = self.view.frame.width
            let loc = sender.location(in: self.view)
            if(loc.x < screenWidth / 2) {
                self.documentIdx -= 1
            } else {
                self.documentIdx += 1
            }
            showImage()
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
        if motion == .motionShake {
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
                            try manager.removeItem(atPath: path)
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
        return
    }
}
