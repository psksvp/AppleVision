//
//  CameraSessionController.swift
//  FaceMe
//
//  Created by psksvp on 15/9/20.
//  Copyright © 2020 psksvp. All rights reserved.
//

import Foundation
import Cocoa
import AVFoundation
import CoreMedia
import CoreImage
import CommonSwift


class CameraSessionController
{
  let session: AVCaptureSession
  let sampleDataOutputQueue: DispatchQueue
  var videoSize: CGSize
  
  init?(_ id: Int,
        _ captureDelegate: AVCaptureVideoDataOutputSampleBufferDelegate,
        _ previewView: NSView?)
  {
    self.session = AVCaptureSession()
    self.sampleDataOutputQueue = DispatchQueue(label: "psksvp.captureDataQueue")
    self.videoSize = CGSize(width: 0, height: 0)
    guard let (input, size) = inputDevice(id) else {return nil}
    self.videoSize = size
    let output = videoDataOutput(captureDelegate, sampleDataOutputQueue)
    self.session.addInput(input)
    self.session.addOutput(output)
    
    if let v = previewView
    {
      setupPreview(v, self.session)
    }
    
    session.startRunning()
  }
  
  deinit
  {
    session.stopRunning()
  }
  
  private func videoDataOutput(_ captureDelegate: AVCaptureVideoDataOutputSampleBufferDelegate,
                               _ sampleQueue: DispatchQueue) -> AVCaptureVideoDataOutput
  {
    let videoDataOutput = AVCaptureVideoDataOutput()
    videoDataOutput.alwaysDiscardsLateVideoFrames = true
    
    videoDataOutput.setSampleBufferDelegate(captureDelegate, queue: sampleQueue)
    videoDataOutput.connection(with: .video)?.isEnabled = true
    return videoDataOutput
  }
  
  private func inputDevice(_ id: Int) -> (AVCaptureInput, CGSize)?
  {
    let deviceList = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .externalUnknown],
                                                        mediaType: .video,
                                                        position: .unspecified).devices
    print(deviceList)
    assert(deviceList.count > 0, "There is no camera avaiable.")
    assert(id < deviceList.count, "deviceID: \(id) does not exist")
    
    do
    {
      guard let devIdx = (id < 0 ? CommonDialogs.listChooser(deviceList.map {$0.localizedName},
                                                       title: "select video capture device:") : id)
      else {return nil}
      let device = deviceList[devIdx]
      print("using device --> \(devIdx) name: \(device.localizedName)")
      let input = try AVCaptureDeviceInput(device: device)
      let dim = CMVideoFormatDescriptionGetDimensions(device.activeFormat.formatDescription)
      return (input, CGSize(width: CGFloat(dim.width), height: CGFloat(dim.height)))
    }
    catch let err as NSError
    {
      print(err)
      return nil
    }
    catch
    {
      print("An unexpected failure has occured")
      return nil
    }
  }
  
  private func setupPreview(_ view: NSView, _ s: AVCaptureSession)
  {
    let videoPreviewLayer = AVCaptureVideoPreviewLayer(session: s)
    videoPreviewLayer.name = "CameraPreview"
    videoPreviewLayer.backgroundColor = NSColor.black.cgColor
    videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
    videoPreviewLayer.bounds = view.bounds
    //drawingLayer.anchorPoint = normalizedCenterPoint
    videoPreviewLayer.position = CGPoint(x: view.bounds.width / 2,
                                         y: view.bounds.height / 2)
    //view.layer?.addSublayer(videoPreviewLayer)
    view.layer?.insertSublayer(videoPreviewLayer, at: 0)
  }
}



