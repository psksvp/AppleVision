//
//  VisionOutputAnnotators.swift
//  FaceMe
//
//  Created by psksvp on 19/9/20.
//  Copyright © 2020 psksvp. All rights reserved.
//

import Foundation
import Vision
import AVFoundation
import CommonSwift


class PID
{
  let kP: Double
  let kI: Double
  let kD: Double
  let setPoint: Double
  let sampleInterval: TimeInterval
  
  private var lastTime = Date().timeIntervalSinceReferenceDate
  private var lastError = 0.0
  private var lastOutout = 0.0
  private var lastIntegral = 0.0
  
  init(_ sp: Double,
       _ p: Double, _ i: Double, _ d: Double,
       sampleInterval s: TimeInterval = 0.01)
  {
    self.kP = p
    self.kI = i
    self.kD = d
    self.setPoint = sp
    self.sampleInterval = s
  }
  
  func step(_ measureValue: Double) -> Double
  {
    let error = self.setPoint - measureValue
    let currentTime = Date().timeIntervalSinceReferenceDate
    let deltaTime = currentTime - self.lastTime
    let deltaError = error - self.lastError
    
    guard deltaTime >= sampleInterval else {return lastOutout}
    
    let p = self.kP * error
    let i = lastIntegral + error * deltaTime  // output limit clamp here
    let d = deltaTime > 0 ? deltaError / deltaTime : 0.0
    let output = p + (self.kI * i) + (self.kD * d)
    
    self.lastError = error
    self.lastTime = currentTime
    self.lastIntegral = i
    self.lastOutout = output
    return output
  }
}

class PanTiltController
{
  let port: SerialPort
  
  var ready:Bool
  {
    if let line = port.readLine()
    {
      print("state: \(line)")
      return line.contains("ready")
    }
    else
    {
      return false
    }
  }
  
  init(portPath: String = "/dev/cu.usbmodem1A12601")
  {
    self.port = SerialPort(path: portPath, baud: .b9600)
    self.port.writeLine("\n");
  }
  
  func sendMove(_ pan: Int, _ tilt: Int)
  {
    print("sendMove, \(pan),\(tilt)")
    port.writeLine("\(pan),\(tilt)")
  }
}


class CenterFaceController
{
  let ptController = PanTiltController()
  
  func step(_ faceRect: CGRect)
  {
    guard ptController.ready else
    {
      print("not ready")
      return
    }
    let (fcx, fcy) = center(faceRect)
    ptController.sendMove(Int(fcx), Int(fcy))
  }
}


func center(_ r: CGRect) -> (Float, Float)
{
  return (Float(r.origin.x) + Float(r.width) / 2,
          Float(r.origin.y) + Float(r.height) / 2)
}


let centerFaceController = CenterFaceController()


func faceServoHead(_ rs: [VNObservation])
{
  if let face = rs.first as? VNFaceObservation
  {
    let fr = VNImageRectForNormalizedRect(face.boundingBox,
                                          640,
                                          480)

    centerFaceController.step(fr) 
  }

}


func faceAnnotator(_ rs: [VNObservation], _ s: CGSize) -> CGPath?
{
  let faceRectanglePath = CGMutablePath()
  for r in rs
  {
    switch r
    {
      case let fov as VNFaceObservation :
        let fr = VNImageRectForNormalizedRect(fov.boundingBox,
                                              Int(s.width),
                                              Int(s.height))
        faceRectanglePath.addRect(fr)
        //print(fr)
        
      default: break
    }
  }
  
  return faceRectanglePath
}

//func scribble(_ rs: [VNObservation], _ s: CGSize) -> CGPath?
//{
//  for r in rs
//  {
//    switch r
//    {
//      case let ob as VNRecognizedPointsObservation :
//        do
//        {
//          let thumbPts = try ob.recognizedPoints(forGroupKey: .handLandmarkRegionKeyThumb)
//          let indexPtss = try ob.recognizedPoints(forGroupKey: .handLandmarkRegionKeyIndexFinger)
//
//        }
//        catch
//        {
//          break
//        }
//    }
//  }
//
//  return nil
//}
