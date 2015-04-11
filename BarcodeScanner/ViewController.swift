//
//  ViewController.swift
//  BarcodeScanner
//
//  Created by Alex Hui on 3/18/15.
//  Copyright (c) 2015 Emobicon. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

    let session = AVCaptureSession()
    var previewLayer : AVCaptureVideoPreviewLayer?
    var identifiedBorder : DiscoveredBarCodeView?
    var timer : NSTimer?
    
    func addPreviewLayer() {
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        previewLayer?.bounds = self.view.bounds
        previewLayer?.position = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds))
        self.view.layer.addSublayer(previewLayer)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let captureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        var error : NSError?
        let inputDevice = AVCaptureDeviceInput(device: captureDevice, error: &error)
        
        if let inp = inputDevice {
            session.addInput(inp)
        } else {
            println(error)
        }
        addPreviewLayer()
        
        identifiedBorder = DiscoveredBarCodeView(frame: self.view.bounds)
        identifiedBorder?.backgroundColor = UIColor.clearColor()
        identifiedBorder?.hidden = true;
        self.view.addSubview(identifiedBorder!)
        
        // Check for metadata
        let output = AVCaptureMetadataOutput()
        session.addOutput(output)
        output.metadataObjectTypes = output.availableMetadataObjectTypes
        println(output.availableMetadataObjectTypes)
        output.setMetadataObjectsDelegate(self, queue: dispatch_get_main_queue())
        session.startRunning()
    }

    override func viewWillAppear(animated: Bool) {
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(animated: Bool) {
        session.stopRunning()
    }

    func translatePoints(points : [AnyObject], fromView : UIView, toView: UIView) -> [CGPoint] {
        var translatedPoints : [CGPoint] = []
        for point in points {
            var dict = point as NSDictionary
            let x = CGFloat((dict.objectForKey("X") as NSNumber).floatValue)
            let y = CGFloat((dict.objectForKey("Y") as NSNumber).floatValue)
            let curr = CGPointMake(x, y)
            let currFinal = fromView.convertPoint(curr, toView: toView)
            translatedPoints.append(currFinal)
        }
        return translatedPoints
    }
    
    func startTimer() {
        if timer?.valid != true {
            timer = NSTimer.scheduledTimerWithTimeInterval(0.2, target: self, selector: "removeBorder", userInfo: nil, repeats: false)
        } else {
            timer?.invalidate()
        }
    }
    
    func removeBorder() {
        // Remove the identified border
        self.identifiedBorder?.hidden = true
    }
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
        for data in metadataObjects {
            let metaData = data as AVMetadataObject
            let transformed = previewLayer?.transformedMetadataObjectForMetadataObject(metaData) as? AVMetadataMachineReadableCodeObject
            if let unwrapped = transformed {
                identifiedBorder?.frame = unwrapped.bounds
                identifiedBorder?.hidden = false
                let identifiedCorners = self.translatePoints(unwrapped.corners, fromView: self.view, toView: self.identifiedBorder!)
                identifiedBorder?.drawBorder(identifiedCorners)
                self.identifiedBorder?.hidden = false
                self.startTimer()
            }
        }
    }
}

