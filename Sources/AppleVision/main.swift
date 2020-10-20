//  Created by psksvp on 15/9/20.
//  Copyright © 2020 psksvp. All rights reserved.
//

import AppKit
import Cocoa
import Vision
import CommonSwift

print("Hello, world!")

//class TestView: NSView
//{
//  override func draw(_ dirtyRect: NSRect)
//  {
//    NSBezierPath.stroke(NSMakeRect(0, 0, 100, 400))
//  }
//}

struct AppleVisionController
{
  private let cam:CameraSessionController?
  private let ft:VisionAnalyzer
  
  init(_ v: NSView,
       _ requests: [VNImageBasedRequest],
       _ resultHandlers: [VisionResultHandler]? = nil,
       _ outputAnnotators: [OutputAnnotator]? = nil)
  {
    ft = VisionAnalyzer(v,
                        requests,
                        resultHandlers,
                        outputAnnotators)
    cam = CameraSessionController(-1, ft, v)
  }
}

class MainController: NSObject, NSApplicationDelegate
{
  var rootWindow: NSWindow? = nil
  var appleVision: AppleVisionController? = nil
  
  func applicationDidFinishLaunching(_ notification: Notification)
  {
    rootWindow = NSWindow(contentRect: NSMakeRect(0, 0, 640, 480),
                          styleMask: [.titled, .closable, .resizable],
                          backing: .buffered,
                          defer: true)
    
    
    rootWindow?.orderFrontRegardless()
    rootWindow?.title = "rootVision"
    NSApplication.shared.activate(ignoringOtherApps: true)
    rootWindow?.contentView?.wantsLayer = true
  
    appleVision = AppleVisionController(rootWindow!.contentView!,
                                        [VNDetectFaceRectanglesRequest()],
                                        [faceServoHead],
                                        [faceAnnotator])
  }
  
  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool
  {
    print("exiting?")
    return true
  }
}


let a = NSApplication.shared
a.setActivationPolicy(.regular)
let m = MainController()
a.delegate = m
a.run()
