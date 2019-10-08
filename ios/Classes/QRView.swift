//
//  QRView.swift
//  flutter_qr
//
//  Created by Julius Canute on 21/12/18.
//

import Foundation
import UIKit
import AVFoundation

public class QRView:NSObject,FlutterPlatformView{
    @IBOutlet var previewView: UIView!
    var registrar: FlutterPluginRegistrar
    var channel: FlutterMethodChannel
    var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var avDevice:AVCaptureDevice?
    var isFrontCamera=false
    
    public init(withFrame frame: CGRect, withRegistrar registrar: FlutterPluginRegistrar, withId id: Int64){
        self.registrar = registrar
        previewView = UIView(frame: frame)
        channel = FlutterMethodChannel(name: "net.touchcapture.qr.flutterqr/qrview_\(id)", binaryMessenger: registrar.messenger())
    }
    
   
//    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
//             NSLog("metadataObjects - - %@", metadataObjects)
//             if let metadataObject = metadataObjects.first {
//                 guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
//                 guard let stringValue = readableObject.stringValue else { return }
//                 AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
//                 self.channel.invokeMethod("onRecognizeQR", arguments: stringValue)
//             }
//
//    }

       
    
    func alert(message:String){
         UIAlertView(title: "二维码扫描", message: message, delegate: nil, cancelButtonTitle: nil, otherButtonTitles: "Ok").show()
    }
    
    func isCameraAvailable(success: Bool) -> Void {
        if success {
            do {
                captureSession = AVCaptureSession()
                captureSession!.sessionPreset=AVCaptureSession.Preset.high
                let position=isFrontCamera ? AVCaptureDevice.Position.front : AVCaptureDevice.Position.back
                if #available(iOS 10.0, *) {
                    guard let videoCaptureDevice = AVCaptureDevice.default(.builtInWideAngleCamera,for: .video, position: position) else {
                        self.alert(message: "无法连接到您的相机")
                        return
                    }
                    avDevice=videoCaptureDevice
                } else {
                    guard let videoCaptureDevice = AVCaptureDevice.devices().filter({ $0.position == position })
                        .first else {
                            self.alert(message: "无法连接到您的相机")
                            return
                    }
                    avDevice=videoCaptureDevice
                }
             
                let videoInput: AVCaptureDeviceInput = try AVCaptureDeviceInput(device: avDevice!)
                if (captureSession!.canAddInput(videoInput)) {
                   captureSession!.addInput(videoInput)
                } else {
                   self.alert(message: "无法从您的相机获取输入流")
                   return
               }

               let metadataOutput = AVCaptureMetadataOutput()

               if (captureSession!.canAddOutput(metadataOutput)) {
                   metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                   captureSession!.addOutput(metadataOutput)
                   metadataOutput.metadataObjectTypes = [.qr,.ean8, .ean13, .pdf417,.code39,.code93,.code128]
                 
               } else {
                   self.alert(message: "无法从您的相机获取输出流")
                   return
               }
               previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
               previewLayer!.frame = previewView.layer.bounds
               previewLayer!.videoGravity = .resizeAspectFill
               previewView!.layer.addSublayer(previewLayer!)

               captureSession!.startRunning()
               
            } catch {
                self.alert(message: "启动相机扫描时发生了错误")
            }
        } else {
            self.alert(message: "您没有授予APP访问相机的权限,请在设置中授予")
        }
    }
    
    func cameraPermissions(authorizedBlock: (() -> Void)?, deniedBlock: (() -> Void)?) {
        let authStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        
        // .notDetermined  .authorized  .restricted  .denied
        if authStatus == .notDetermined {
            // 第一次触发授权 alert
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { (granted: Bool) in
                self.cameraPermissions(authorizedBlock: authorizedBlock, deniedBlock: deniedBlock)
            })
        } else if authStatus == .authorized {
            if authorizedBlock != nil {
                authorizedBlock!()
            }
        } else {
            if deniedBlock != nil {
                deniedBlock!()
            }
        }
    }
    
    public func view() -> UIView {
        channel.setMethodCallHandler({
            [weak self] (call: FlutterMethodCall, result: FlutterResult) -> Void in
            switch(call.method){
                case "setDimensions":
                    let arguments = call.arguments as! Dictionary<String, Double>
                    self?.setDimensions(width: arguments["width"] ?? 0,height: arguments["height"] ?? 0)
                case "flipCamera":
                    self?.flipCamera()
                case "toggleFlash":
                    self?.toggleFlash()
                case "pauseCamera":
                    self?.pauseCamera()
                case "resumeCamera":
                    self?.resumeCamera()
                default:
                    result(FlutterMethodNotImplemented)
                    return
            }
        })
        return previewView
    }
    
    func setDimensions(width: Double, height: Double) -> Void {
        previewView.frame = CGRect(x: 0, y: 0, width: width, height: height)
       
        self.cameraPermissions(authorizedBlock: {
            self.isCameraAvailable(success:true)
        }, deniedBlock: {
            self.isCameraAvailable(success:false)
        })
        
    }
    
   
    func flipCamera(){
        if (avDevice != nil) {
            captureSession!.stopRunning()
            isFrontCamera = !isFrontCamera
         
            isCameraAvailable(success: true);
        }
    }
    
    func toggleFlash(){
        if(avDevice!.hasTorch){
            do
            {
                try avDevice!.lockForConfiguration()
                avDevice!.torchMode=(avDevice!.torchMode==AVCaptureDevice.TorchMode.on ? AVCaptureDevice.TorchMode.off:AVCaptureDevice.TorchMode.on)
                avDevice!.unlockForConfiguration()
            }
            catch
            {
                NSLog("无法打开闪光灯")
            }
        }
    }
    
    func pauseCamera() {
        captureSession!.stopRunning()
    }
    
    func resumeCamera() {
        captureSession!.startRunning()
    }
}
// MARK: - AVCaptureMetadataOutputObjectsDelegate
extension QRView:AVCaptureMetadataOutputObjectsDelegate{
    
    public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection){
        NSLog("metadataObjects - - %@", metadataObjects)
        if let metadataObject = metadataObjects.first {
           guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
           guard let stringValue = readableObject.stringValue else { return }
           AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
           self.channel.invokeMethod("onRecognizeQR", arguments: stringValue)
        }
    }
    
}
