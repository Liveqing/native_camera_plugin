import Flutter
import UIKit
import AVFoundation
import Photos

public class NativeCameraPlugin: NSObject, FlutterPlugin {
    private var pendingResult: FlutterResult?
    private var cameraOptions: [String: Any]?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "native_camera_plugin", binaryMessenger: registrar.messenger())
        let instance = NativeCameraPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)
        case "checkCameraPermission":
            checkCameraPermission(result: result)
        case "requestCameraPermission":
            requestCameraPermission(result: result)
        case "isCameraAvailable":
            result(isCameraAvailable())
        case "takePicture":
            takePicture(call: call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func checkCameraPermission(result: @escaping FlutterResult) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        result(status == .authorized)
    }
    
    private func requestCameraPermission(result: @escaping FlutterResult) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            result(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    result(granted)
                }
            }
        case .denied, .restricted:
            result(false)
        @unknown default:
            result(false)
        }
    }
    
    private func isCameraAvailable() -> Bool {
        return UIImagePickerController.isSourceTypeAvailable(.camera)
    }
    
    private func takePicture(call: FlutterMethodCall, result: @escaping FlutterResult) {
        // 检查相机权限
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        guard cameraStatus == .authorized else {
            result(FlutterError(code: "PERMISSION_DENIED", message: "Camera permission not granted", details: nil))
            return
        }
        
        // 检查相机是否可用
        guard isCameraAvailable() else {
            result(FlutterError(code: "CAMERA_NOT_AVAILABLE", message: "Camera is not available on this device", details: nil))
            return
        }
        
        // 获取当前的视图控制器
        guard let viewController = UIApplication.shared.keyWindow?.rootViewController else {
            result(FlutterError(code: "NO_VIEW_CONTROLLER", message: "No view controller available", details: nil))
            return
        }
        
        // 保存参数和结果回调
        self.cameraOptions = call.arguments as? [String: Any]
        self.pendingResult = result
        
        // 创建图像选择器
        let imagePickerController = UIImagePickerController()
        imagePickerController.sourceType = .camera
        imagePickerController.mediaTypes = ["public.image"]
        imagePickerController.allowsEditing = false
        imagePickerController.delegate = self
        
        // 设置相机质量
        if let options = cameraOptions,
           let quality = options["quality"] as? Double {
            let cameraQuality: UIImagePickerController.QualityType
            if quality >= 0.8 {
                cameraQuality = .high
            } else if quality >= 0.5 {
                cameraQuality = .medium
            } else {
                cameraQuality = .low
            }
            imagePickerController.videoQuality = cameraQuality
        }
        
        // 显示相机界面
        viewController.present(imagePickerController, animated: true, completion: nil)
    }
    
    private func processImage(_ image: UIImage) -> [String: Any] {
        guard let options = cameraOptions else {
            return ["success": false, "error": "No camera options available"]
        }
        
        let quality = options["quality"] as? Double ?? 0.8
        let maxWidth = options["maxWidth"] as? Int
        let maxHeight = options["maxHeight"] as? Int
        let includeImageData = options["includeImageData"] as? Bool ?? false
        let saveToGallery = options["saveToGallery"] as? Bool ?? true
        
        var processedImage = image
        
        // 调整图片尺寸
        if let maxWidth = maxWidth, let maxHeight = maxHeight {
            processedImage = resizeImage(processedImage, maxWidth: maxWidth, maxHeight: maxHeight)
        } else if let maxWidth = maxWidth {
            processedImage = resizeImage(processedImage, maxWidth: maxWidth, maxHeight: nil)
        } else if let maxHeight = maxHeight {
            processedImage = resizeImage(processedImage, maxWidth: nil, maxHeight: maxHeight)
        }
        
        // 压缩图片
        guard let imageData = processedImage.jpegData(compressionQuality: quality) else {
            return ["success": false, "error": "Failed to compress image"]
        }
        
        var result: [String: Any] = ["success": true]
        
        // 保存图片
        do {
            let imagePath: String
            if saveToGallery {
                imagePath = try saveImageToGallery(imageData)
            } else {
                imagePath = try saveImageToTempDirectory(imageData)
            }
            result["imagePath"] = imagePath
        } catch {
            return ["success": false, "error": "Failed to save image: \(error.localizedDescription)"]
        }
        
        // 如果需要返回图片数据
        if includeImageData {
            result["imageData"] = [UInt8](imageData)
        }
        
        return result
    }
    
    private func resizeImage(_ image: UIImage, maxWidth: Int?, maxHeight: Int?) -> UIImage {
        let size = image.size
        
        guard maxWidth != nil || maxHeight != nil else {
            return image
        }
        
        let targetWidth = maxWidth.map { CGFloat($0) } ?? size.width
        let targetHeight = maxHeight.map { CGFloat($0) } ?? size.height
        
        let scaleX = targetWidth / size.width
        let scaleY = targetHeight / size.height
        let scale = min(scaleX, scaleY)
        
        if scale >= 1.0 {
            return image
        }
        
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage ?? image
    }
    
    private func saveImageToGallery(_ imageData: Data) throws -> String {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let fileName = "IMG_\(Date().timeIntervalSince1970).jpg"
        let filePath = "\(documentsPath)/\(fileName)"
        
        try imageData.write(to: URL(fileURLWithPath: filePath))
        
        // 保存到相册
        if let image = UIImage(data: imageData) {
            PHPhotoLibrary.requestAuthorization { status in
                if status == .authorized {
                    PHPhotoLibrary.shared().performChanges({
                        PHAssetChangeRequest.creationRequestForAsset(from: image)
                    }, completionHandler: nil)
                }
            }
        }
        
        return filePath
    }
    
    private func saveImageToTempDirectory(_ imageData: Data) throws -> String {
        let tempDir = NSTemporaryDirectory()
        let fileName = "temp_camera_\(Date().timeIntervalSince1970).jpg"
        let filePath = "\(tempDir)\(fileName)"
        
        try imageData.write(to: URL(fileURLWithPath: filePath))
        
        return filePath
    }
}

// MARK: - UIImagePickerControllerDelegate
extension NativeCameraPlugin: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true) {
            guard let image = info[.originalImage] as? UIImage else {
                self.pendingResult?(FlutterError(code: "IMAGE_ERROR", message: "Failed to get image from camera", details: nil))
                self.pendingResult = nil
                return
            }
            
            let result = self.processImage(image)
            self.pendingResult?(result)
            self.pendingResult = nil
        }
    }
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true) {
            self.pendingResult?(FlutterError(code: "USER_CANCELLED", message: "User cancelled camera operation", details: nil))
            self.pendingResult = nil
        }
    }
}
