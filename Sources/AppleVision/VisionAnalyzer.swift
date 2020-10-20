//
//  VisionAnalyzer.swift
//  FaceMe
//
//  Created by psksvp on 19/9/20.
//  Copyright © 2020 psksvp. All rights reserved.
//

import Foundation
import Cocoa
import AVKit
import Vision
import CoreImage

typealias VisionResultHandler = (([VNObservation]) -> Void)
typealias OutputAnnotator = (([VNObservation], CGSize)-> CGPath?)

extension Collection where Element == VNImageBasedRequest
{
  func visionAnalysis(_ pixels: CVPixelBuffer) ->[VNObservation]?
  {
    do
    {
      let requests = self as! [VNImageBasedRequest]
      try VNSequenceRequestHandler().perform(requests,
                                             on: pixels,
                                             orientation: .up)
      let ar = requests.compactMap {$0.results}
      return Array(ar.joined()).map {$0 as! VNObservation}
    }
    catch
    {
      // TODO: Pump Errors
      return nil
    }
  }
}


class VisionAnalyzer : NSObject, AVCaptureVideoDataOutputSampleBufferDelegate
{
  struct AnnotationLayer
  {
    let calayer = CAShapeLayer()
    
    init(_ v: NSView)
    {
      calayer.name = "annotationLayer"
      calayer.bounds = v.bounds
 
      calayer.position = CGPoint(x: v.bounds.width / 2,
                                 y: v.bounds.height / 2)
      calayer.fillColor = nil
      calayer.strokeColor = NSColor.green.withAlphaComponent(0.7).cgColor
      calayer.lineWidth = 1
      calayer.shadowOpacity = 0.7
      calayer.shadowRadius = 5
      v.layer?.addSublayer(calayer)
    }
    
    func draw(_ p: CGPath)
    {
      CATransaction.begin()
      CATransaction.setValue(NSNumber(value: true), forKey: kCATransactionDisableActions)
      self.calayer.path = p
      CATransaction.commit()
    }
  }
  
  let view: NSView
  let drawingLayer: AnnotationLayer
  let vnRequests: [VNImageBasedRequest]
  let resultHandlers: [VisionResultHandler]?
  let outputAnnotators: [OutputAnnotator]?
  
  init(_ v: NSView,
       _ vnq: [VNImageBasedRequest],
       _ p: [VisionResultHandler]? = nil,
       _ a: [OutputAnnotator]? = nil)
  {
    self.view = v
    drawingLayer = AnnotationLayer(v)
    vnRequests = vnq
    resultHandlers = p
    outputAnnotators = a
  }
  
  
  func captureOutput(_ output: AVCaptureOutput,
                     didOutput sampleBuffer: CMSampleBuffer,
                     from connection: AVCaptureConnection)
  {
    guard let pixels = CMSampleBufferGetImageBuffer(sampleBuffer) else
    {
      print("Error: Fail to get image pixels buffer..")
      return
    }
    
    guard let r = self.vnRequests.visionAnalysis(pixels) else
    {
      print("vnRequests.visionAnalysis(pixels) return nil")
      return
    }
    
    resultHandlers?.forEach {$0(r)}
    
    DispatchQueue.main.async
    {
      let paths = CGMutablePath()
      self.outputAnnotators?.forEach
      {
        if let p = $0(r, self.view.bounds.size)
        {
          paths.addPath(p)
        }
      }
      self.drawingLayer.draw(paths)
    }
    
  }
}



