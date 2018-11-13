//
//  ViewController.swift
//  Camz
//
//  Created by Kenji on 11/5/18.
//  Copyright © 2018 SaigonMD. All rights reserved.
//

import UIKit
import AVFoundation
import MobileCoreServices

class ViewController: UIViewController {

  let captureSession = AVCaptureSession()
  var videoPreviewLayer: AVCaptureVideoPreviewLayer?
  var captureDevice: AVCaptureDevice?
  var videoOutput = AVCaptureMovieFileOutput()
  
  override func viewDidLoad() {
    super.viewDidLoad()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    self.initCamera()
  }
  
  @IBOutlet var recordButton: UIButton!
  
  @IBAction func recordButtonTapped(_ sender: UIButton) {
    if !self.videoOutput.isRecording {
      self.startRecord()
      self.recordButton.setTitle("Stop", for: .normal)
    } else {
      self.stopRecord()
      self.recordButton.setTitle("Start", for: .normal)
    }
  }
  
  func initCamera() {
    print("initCamera")
    
    let devices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .front).devices
    
    if (devices.count > 0) {
      self.captureDevice = devices[0];
      self.startSession()
    }
  }
  
  func startSession() {
    print("startSession")
    
    self.captureSession.sessionPreset = .medium
    
    // add input
    do {
      try self.captureSession.addInput(AVCaptureDeviceInput(device: captureDevice!))
    } catch {
      print("startSession: add input error: \(error)")
    }
    
    // add output
    if self.captureSession.canAddOutput(self.videoOutput) {
      self.captureSession.addOutput(self.videoOutput);
    } else {
      print("startSession: add output error")
    }
    
    self.configureDevice()
    
    self.videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
    self.view.layer.addSublayer(videoPreviewLayer!)
    self.videoPreviewLayer?.frame = self.view.layer.frame
    
    self.captureSession.startRunning()
  }
  
  func configureDevice() {
    print("configureDevice")
    
    guard let device = self.captureDevice else {
      return
    }
    
    var maxFrameRate: Float64 = 0.0
    var maxWidth: Int32 = 0
    var targetFormat: AVCaptureDevice.Format? = nil
    
    for format in captureDevice!.formats {
      
      var ranges = format.videoSupportedFrameRateRanges as [AVFrameRateRange]
      let frameRate = ranges[0].maxFrameRate
      let desc = format.formatDescription
      let dimensions = CMVideoFormatDescriptionGetDimensions(desc)
      let width = dimensions.width
      
      if frameRate >= maxFrameRate && width >= maxWidth {
        targetFormat = format
        maxFrameRate = frameRate
        maxWidth = width
      }
    }
    
    print("configureDevice: fps: \(maxFrameRate); width: \(maxWidth)")
    
    do {
      try device.lockForConfiguration()
      device.activeFormat = targetFormat!
      device.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: Int32(maxFrameRate))
      device.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: Int32(maxFrameRate))
      device.unlockForConfiguration()
    } catch {
      print("configureDevice: error: \(error)")
    }

    
    
  }
  
  func startRecord() {
    if !self.videoOutput.isRecording {
      let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
      let fileUrl = paths[0].appendingPathComponent("output.mov")
      try? FileManager.default.removeItem(at: fileUrl)
      self.videoOutput.startRecording(to: fileUrl, recordingDelegate: self)
    }
  }
  
  func stopRecord() {
    if self.videoOutput.isRecording {
      self.videoOutput.stopRecording()
    }
  }
  
}

extension ViewController: AVCaptureFileOutputRecordingDelegate {
  func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
    if (error == nil) {
      UISaveVideoAtPathToSavedPhotosAlbum(outputFileURL.path, nil, nil, nil)
    }
  }
}
