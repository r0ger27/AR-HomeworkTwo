//
//  ViewController.swift
//  AR-HomeworkTwo
//
//  Created by Ruslan Safin on 23/05/2019.
//  Copyright © 2019 Ruslan Safin. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
    
    // MARK: - Outlets
    @IBOutlet var sceneView: ARSCNView!
    
    // MARK: - Vars
    var planeCounter = 0
    var isHoopPlaced = false
    
    // MARK: - Override methods
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.vertical]
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
}

// MARK: - Extension One
extension ViewController {
    
    // MARK: - Methods
    private func addHoop(result: ARHitTestResult) {
        let hoopScene = SCNScene(named: "art.scnassets/Hoop.scn")
        
        guard let hoopNode = hoopScene?.rootNode.childNode(withName: "Hoop", recursively: false) else { return }
        
        backboardTexture: if let backboardImage = UIImage(named: "art.scnassets/backboard.jpg") {
            guard let backboardNode = hoopNode.childNode(withName: "backboard", recursively: false) else {
                break backboardTexture
            }
            guard let backboard = backboardNode.geometry as? SCNBox else { break backboardTexture }
            backboard.firstMaterial?.diffuse.contents = backboardImage
        }
        
        hoopNode.simdTransform = result.worldTransform
        hoopNode.eulerAngles = SCNVector3(0, 0, 0)
        
        sceneView.scene.rootNode.enumerateChildNodes { node, _ in
            if node.name == "Wall" {
                node.removeFromParentNode()
            }
        }
        sceneView.scene.rootNode.addChildNode(hoopNode)
        isHoopPlaced = true
    }
}

// MARK: - Extension Two
extension ViewController {

    @IBAction func screenTaped(_ sender: UITapGestureRecognizer) {
        if isHoopPlaced {
            
        } else {
            let location = sender.location(in: sceneView)
            
            guard let result = sceneView.hitTest(location, types: [.existingPlaneUsingExtent]).first else { return }
            addHoop(result: result)
        }
    }
}

// MARK: - Extension Three
extension ViewController {
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let anchor = anchor as? ARPlaneAnchor else { return }
        guard !isHoopPlaced else { return }
        
        let extent = anchor.extent
        let width = CGFloat(extent.x)
        let height = CGFloat(extent.z)
        let plane = SCNPlane(width: width, height: height)
        
        plane.firstMaterial?.diffuse.contents = UIColor.red
        let planeNode = SCNNode(geometry: plane)
        
        planeNode.eulerAngles.x = -.pi / 2
        plane.name = "Wall"
        planeNode.opacity = 0.125
        
        node.addChildNode(planeNode)
        planeCounter += 1
        print(#line, "Planes added: \(planeCounter)")
    }
}
