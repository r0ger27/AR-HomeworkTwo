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

enum collisions: Int {
    case none = 0
    case ball = 1
    case start = 2
    case end = 3
}

class ViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var topScore: UILabel!
    @IBOutlet var score: UILabel!
    
    // MARK: - Vars
    var planeCounter = 0
    var topsScore = 0
    var scores = 0
    var isHoopPlaced = false
    var ballCollision = false
    var resultCollision = false
    
    // MARK: - Override methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.scene.physicsWorld.contactDelegate = self
        
        score.isHidden = true
        topScore.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .vertical
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
        guard let backboardNode = hoopNode.childNode(withName: "backboard", recursively: false) else { return }
        guard let ringNode = backboardNode.childNode(withName: "ring", recursively: false) else { return }
        guard let goalNode = ringNode.childNode(withName: "goal", recursively: false) else { return }
        
        backboardTexture: if let backboardImage = UIImage(named: "art.scnassets/backboard.jpg") {
            guard let backboard = backboardNode.geometry as? SCNBox else { break backboardTexture }
            backboard.firstMaterial?.diffuse.contents = backboardImage
        }
        
        hoopNode.simdTransform = result.worldTransform
        hoopNode.eulerAngles.x -= .pi / 2
        hoopNode.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: hoopNode, options: [SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron]))
        
        goalNode.name = "goal"
        goalNode.geometry?.firstMaterial?.diffuse.contents = UIColor.clear
        goalNode.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: goalNode, options: [SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron]))
        
        ringNode.name = "ring"
        ringNode.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: ringNode, options: [SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron]))
        
        goalNode.physicsBody?.categoryBitMask = collisions.start.rawValue
        goalNode.physicsBody?.collisionBitMask = collisions.ball.rawValue
        goalNode.physicsBody?.contactTestBitMask = collisions.ball.rawValue
        ringNode.physicsBody?.categoryBitMask = collisions.end.rawValue
        ringNode.physicsBody?.collisionBitMask = collisions.ball.rawValue
        ringNode.physicsBody?.contactTestBitMask = collisions.ball.rawValue
        
        sceneView.scene.rootNode.enumerateChildNodes { node, _ in
            if node.name == "Wall" {
                node.removeFromParentNode()
            }
        }
        
        sceneView.scene.rootNode.addChildNode(hoopNode)
        stopDetectPlane()
        
        isHoopPlaced = true
        score.isHidden = false
        topScore.isHidden = false
    }
    
    func createBasketball() {
        guard let frame = sceneView.session.currentFrame else { return }
        
        let ball = SCNNode(geometry: SCNSphere(radius: 0.2))
        ball.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "art.scnassets/basketball.jpg")
        ball.name = "ball"
        
        let cameraTransform = SCNMatrix4(frame.camera.transform)
        ball.transform = cameraTransform
        
        let physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: ball,options: [SCNPhysicsShape.Option.collisionMargin: 0.01]))
        ball.physicsBody = physicsBody
        
        let power = Float(10)
        let x = -cameraTransform.m31 * power
        let y = -cameraTransform.m32 * power
        let z = -cameraTransform.m33 * power
        let force = SCNVector3(x, y, z)
        
        ball.physicsBody?.applyForce(force, asImpulse: true)
        
        ball.categoryBitMask = collisions.ball.rawValue
        
        physicsBody.collisionBitMask = collisions.start.rawValue | collisions.end.rawValue | collisions.ball.rawValue
        physicsBody.contactTestBitMask = collisions.start.rawValue | collisions.end.rawValue | collisions.ball.rawValue
        
        sceneView.scene.rootNode.addChildNode(ball)
    }
}

// MARK: - Extension Two
extension ViewController {
    
    @IBAction func screenTaped(_ sender: UITapGestureRecognizer) {
        if isHoopPlaced {
            createBasketball()
        } else {
            let location = sender.location(in: sceneView)
            guard let result = sceneView.hitTest(location, types: [.existingPlaneUsingExtent]).first else { return }
            addHoop(result: result)
        }
    }
}

// MARK: - Extension Three
extension ViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let anchor = anchor as? ARPlaneAnchor else { return }
        guard !isHoopPlaced else { return }
        
        let extent = anchor.extent
        let width = CGFloat(extent.x)
        let height = CGFloat(extent.z)
        let plane = SCNPlane(width: width, height: height)
        
        plane.firstMaterial?.diffuse.contents = UIColor.blue
        
        let planeNode = SCNNode(geometry: plane)
        
        planeNode.eulerAngles.x = -.pi / 2
        planeNode.name = "Wall"
        planeNode.opacity = 0.125
        
        node.addChildNode(planeNode)
        planeCounter += 1
    }
    
    func stopDetectPlane() {
        guard let configuration = sceneView.session.configuration as? ARWorldTrackingConfiguration else { return }
        
        configuration.planeDetection = []
        sceneView.session.run(configuration)
    }
}


extension ViewController: SCNPhysicsContactDelegate {
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        
        if ballCollision == false {
            if (contact.nodeA.name! == "ball" && contact.nodeB.name! == "goal") {
                ballCollision.toggle()
            }
        }
        
        if (ballCollision == true) && (resultCollision == false) {
            if (contact.nodeA.name! == "ball" && contact.nodeB.name! == "ring") {
                ballCollision.toggle()
                
                scores += 1
                
                DispatchQueue.main.async {
                    if self.scores >= self.topsScore {
                        self.topsScore = self.scores
                    }
                    
                    self.score.text = "Scores: \(self.scores)"
                    self.topScore.text = "Top Score: \(self.topsScore)"
                }
                
            }
        }
    }
}
