//
//  ViewController.swift
//  ViewAR
//
//  Created by kazunobu on 2018/07/12.
//  Copyright © 2018年 kazunobu. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import FileBrowser
import Zip

class ViewController: UIViewController, ARSCNViewDelegate {
    let documentsDirectory = FileManager.default.temporaryDirectory
    var documentList : [String] = []
    var documentIdx : Int = 0
    @IBOutlet var sceneView: ARSCNView!
    
    private func changeImage() {
        if(documentList.count > 0) {
            if(NSString(string: documentList[documentIdx]).pathExtension == "scn") {
                print("called")
                do {
                    try sceneView.scene = SCNScene(url: URL(fileURLWithPath: documentsDirectory.path + "/" + documentList[documentIdx]))
                    sceneView.autoenablesDefaultLighting = true
                } catch {
                    print("error")
                }
            } else {
                print("non scn")
            }
            documentIdx += 1
            documentIdx %= documentList.count
        } else {
            loadsObjs()
        }
    }
    
    private func loadsObjs() {
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
                cself.documentList = try manager.contentsOfDirectory(atPath: cself.documentsDirectory.path)
                cself.documentIdx = 0
            } catch {
                let alert: UIAlertController = UIAlertController(title: "Some error.", message: "Some error while reading file.", preferredStyle:  UIAlertControllerStyle.alert)
                let defaultAction: UIAlertAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default)
                alert.addAction(defaultAction)
                cself.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene(named: "art.scnassets/ship.scn")!
        
        // Set the scene to the view
        sceneView.scene = scene
        sceneView.autoenablesDefaultLighting = true
        sceneView.addGestureRecognizer(UITapGestureRecognizer(
            target: self, action: #selector(self.tapView(sender:))))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        // Horizontal plane detection.
        configuration.planeDetection = .horizontal
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    // MARK: - ARSCNViewDelegate
  
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
        return node
    }
    
    @objc func tapView(sender: UITapGestureRecognizer) {
        changeImage()
        return
    }
    
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        if (motion == .motionShake || motion == .remoteControlNextTrack) {
            if(self.documentList.count <= 0) {
                self.changeImage()
            }
        }
        return
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}