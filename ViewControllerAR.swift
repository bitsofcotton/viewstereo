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
    var documentIdx  : Int = 0
    @IBOutlet var sceneView: ARSCNView!
    
    private func changeImage() {
        if(documentList.count > 0 && documentIdx < documentList.count) {
            do {
                try sceneView.scene = SCNScene(url: URL(fileURLWithPath: documentsDirectory.path + "/" + documentList[documentIdx]))
                let ambientLightNode = SCNNode()
                ambientLightNode.light = SCNLight()
                ambientLightNode.light!.type = .ambient
                ambientLightNode.light!.color = UIColor.white
                sceneView.scene.rootNode.addChildNode(ambientLightNode)
                sceneView.autoenablesDefaultLighting = true
            } catch {
                return
            }
            documentIdx += 1
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
                let list = try manager.contentsOfDirectory(atPath: cself.documentsDirectory.path)
                for path in list {
                    try! manager.removeItem(atPath: cself.documentsDirectory.path + "/" + path)
                }
                try Zip.unzipFile(file.filePath, destination: cself.documentsDirectory, overwrite: true, password: "", progress: { (progress) -> () in
                    
                })
                cself.documentList = []
                cself.documentIdx = 0
                let rawarray = try manager.contentsOfDirectory(atPath: cself.documentsDirectory.path)
                for raw in rawarray {
                    if(NSString(string: raw).pathExtension == "scn" ||
                        NSString(string: raw).pathExtension == "scnz") {
                        cself.documentList.insert(raw, at: cself.documentList.count)
                    }
                }
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
        sceneView.delegate = self
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        let scene = SCNScene()
        sceneView.scene = scene
        sceneView.autoenablesDefaultLighting = true
        sceneView.addGestureRecognizer(UITapGestureRecognizer(
            target: self, action: #selector(self.tapView(sender:))))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
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
