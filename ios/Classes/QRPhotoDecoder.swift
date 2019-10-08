//
//  QRPhotoDecoder.swift
//  Pods-Runner
//
//  Created by qinjilei on 2019/10/8.
//

import Foundation
import Flutter

public class QRPhotoDecoder{
    var registrar:FlutterPluginRegistrar
    var channel: FlutterMethodChannel
    
    public init(registrar: FlutterPluginRegistrar){
        self.registrar=registrar;
        self.channel = FlutterMethodChannel(name: "net.touchcapture.qr.flutterqr/photo_decoder", binaryMessenger: registrar.messenger())
        setHandler(_self: self)
    }
    
    func prasePhoto(path: String) {
        let context = CIContext(options: nil)
        let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: context, options: [CIDetectorAccuracy:CIDetectorAccuracyHigh])
        guard let img = CIImage(contentsOf: URL.init(fileURLWithPath: path)) else {
            self.setResult(resut: "")
            NSLog("路径不存在文件:%@", path)
            return
        }
        let features = detector?.features(in: img)
        if (features!.count >= 1){
            for feature in features! {
                let qrFeature=feature as! CIQRCodeFeature;
                setResult(resut: qrFeature.messageString!)
                return
            }
        }else{
           self.setResult(resut: "")
        }
    }
    
    func setHandler(_self:QRPhotoDecoder)  {
        channel.setMethodCallHandler({
           (call: FlutterMethodCall, result: FlutterResult) -> Void in
             switch(call.method){
                case "decode":
                    let args = call.arguments as! String
                    _self.prasePhoto(path: args)
                default:
                    result(FlutterMethodNotImplemented)
                    return
            }
        })
    }
    
    func setResult(resut:String) {
        channel.invokeMethod("onDecodeQR", arguments: resut)
    }
    
    
    
    
}
