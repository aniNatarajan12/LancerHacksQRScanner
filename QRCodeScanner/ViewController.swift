//
//  ViewController.swift
//  QRCodeScanner
//
//  Created by Anirudh Natarajan on 2/19/20.
//  Copyright © 2020 Anirudh Natarajan. All rights reserved.
//

import AVFoundation
import UIKit
import Firebase

class ViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    
    @IBOutlet var cameraView: UIView!
    @IBOutlet var textLabel: UILabel!
    @IBOutlet var pickerView: UIPickerView!
    @IBOutlet var addButton: UIButton!
    
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var qrCodeFrameView: UIView!
    var lastScanned = ""
    var events = [["Programming Question #1", "Programming Question #2", "Programming Question #3", "Programming Question #4", "Brainstorm Workshop", "Web Workshop", "App Workshop", "Afternoon Speaker Session", "Presentation Workshop", "Meeting Someone From Another School", "Asking Someone For Help", "Eating Lunch", "Eating Dinner", "Team Up With Someone From Another School", "Talk To A Mentor"], [10, 20, 30, 50, 15, 15, 15, 15, 15, 5, 5, 3, 3, 5, 5], ["snowman", "earth", "crown", "treasure", "fox", "laptop", "elephant", "tree", "mountain", "UFO", "glasses", "apple", "donut", "basketball", "books"]]
    var lastEvent = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        
        lastEvent = 0
        addButton.layer.cornerRadius = 20
        textLabel.text = "  Please Scan"
        
        pickerView.delegate = self
        pickerView.dataSource = self
        
        captureSession = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }

        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            failed()
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            failed()
            return
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = cameraView.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        cameraView.layer.addSublayer(previewLayer)

        captureSession.startRunning()
        
        qrCodeFrameView = UIView()
        qrCodeFrameView.layer.borderColor = UIColor.green.cgColor
        qrCodeFrameView.layer.borderWidth = 2
        cameraView.addSubview(qrCodeFrameView)
        cameraView.bringSubviewToFront(qrCodeFrameView)
    }

    func failed() {
        let ac = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning a code from an item. Please use a device with a camera.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
        captureSession = nil
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if (captureSession?.isRunning == false) {
            captureSession.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if (captureSession?.isRunning == true) {
            captureSession.stopRunning()
        }
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        // Check if the metadataObjects array is not nil and it contains at least one object.
        if metadataObjects.count == 0 {
            qrCodeFrameView?.frame = CGRect.zero
//            textLabel.text = "No QR code is detected"
            return
        }
        
        // Get the metadata object.
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        
        if metadataObj.type == AVMetadataObject.ObjectType.qr {
            // If the found metadata is equal to the QR code metadata then update the status label's text and set the bounds
            let barCodeObject = previewLayer?.transformedMetadataObject(for: metadataObj)
            qrCodeFrameView?.frame = barCodeObject!.bounds
            
            if let email = metadataObj.stringValue {
                let code = getUsername(text: email)
                if textLabel.text != code && lastScanned != code {
                    lastScanned = code
                    AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                    textLabel.text = "  User: \(code)"
                }
            }
        }

        dismiss(animated: true)
    }
    
    func getUsername(text: String) -> String {
//        let x = "\(text.split(separator: "/")[1])"
//        var t = "\(x.split(separator: "@")[0])"
        var t = "\(text.split(separator: "@")[0])"
        t = t.replacingOccurrences(of: ".", with: "", options: NSString.CompareOptions.literal, range:nil)
        t = t.replacingOccurrences(of: "#", with: "", options: NSString.CompareOptions.literal, range:nil)
        t = t.replacingOccurrences(of: "$", with: "", options: NSString.CompareOptions.literal, range:nil)
        t = t.replacingOccurrences(of: "[", with: "", options: NSString.CompareOptions.literal, range:nil)
        t = t.replacingOccurrences(of: "]", with: "", options: NSString.CompareOptions.literal, range:nil)
        return t.lowercased()
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return events[0].count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return events[0][row] as! String
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        lastEvent = row
    }
    
    @IBAction func addPressed(_ sender: Any) {
        if textLabel.text == "  Please Scan" {
            let ac = UIAlertController(title: "Error", message: "Please scan a QR code before adding points", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
            return
        }
        
        captureSession.stopRunning()
        first()
    }
    
    func first() {
        let ref = Database.database().reference(fromURL: "https://lancerhacks20.firebaseio.com/")
        
        var imagesScanned = [String]()
        imagesScanned = []
        ref.child("Images").child(lastScanned).observeSingleEvent(of: .value, with: { (snapshot) in
            for child in snapshot.children {
                let snap = child as! DataSnapshot
                let key = snap.key
                imagesScanned.append("\(key)")
            }
            self.second(imagesScanned: imagesScanned)
        })
    }
    
    func second(imagesScanned: [String]) {
        let ref = Database.database().reference(fromURL: "https://lancerhacks20.firebaseio.com/")
        
        if imagesScanned.contains(events[2][lastEvent] as! String) {
            let ac = UIAlertController(title: "Error", message: "\(lastScanned) has already claimed \(events[1][lastEvent]) points for \(events[0][lastEvent])", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
                self.captureSession.startRunning()
            }))
            present(ac, animated: true)
            return
        }
        
        let v = [events[2][lastEvent] as! String: "scanned"]
        ref.child("Images").child(lastScanned).updateChildValues(v, withCompletionBlock: { (err, ref) in
            if err != nil {
                print(err)
                return
            }
        })
        
        var score = 0
        ref.child("Scores").observeSingleEvent(of: .value, with: { (snapshot) in
            for child in snapshot.children {
                let snap = child as! DataSnapshot
                let key = snap.key
                let value = "\(String(describing: snap.value))"
                let x = value.split(separator: "(")[1]
                let y = String(x.dropLast())
                if "\(key)" == self.lastScanned {
                    score = Int(y)!
                    break
                }
            }
            self.third(score: score)
        })
    }
    
    func third(score: Int) {
        let ref = Database.database().reference(fromURL: "https://lancerhacks20.firebaseio.com/")
        
        let newScore = "\(events[1][lastEvent])"
        let v = [lastScanned: "\(score + Int(newScore)!)"]
        ref.child("Scores").updateChildValues(v, withCompletionBlock: { (err, ref) in
            if err != nil {
                print(err)
                return
            }
        })
        
        let ac = UIAlertController(title: "Success", message: "\(lastScanned) has claimed \(events[1][lastEvent]) points for \(events[0][lastEvent]). They now have \(score + Int(newScore)!) points.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            self.captureSession.startRunning()
        }))
        present(ac, animated: true)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
}
