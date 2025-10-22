import 'dart:typed_data';
import 'native_camera_plugin_platform_interface.dart';

/// 相机拍照结果
class CameraResult {
  final String? imagePath;
  final Uint8List? imageData;
  final String? error;
  final bool success;

  CameraResult({
    this.imagePath,
    this.imageData,
    this.error,
    required this.success,
  });

  factory CameraResult.success({String? imagePath, Uint8List? imageData}) {
    return CameraResult(
      imagePath: imagePath,
      imageData: imageData,
      success: true,
    );
  }

  factory CameraResult.error(String error) {
    return CameraResult(error: error, success: false);
  }
}

/// 拍照配置选项
class CameraOptions {
  /// 图片质量 (0.0 - 1.0)
  final double quality;

  /// 最大宽度
  final int? maxWidth;

  /// 最大高度
  final int? maxHeight;

  /// 是否返回图片数据 (默认只返回路径)
  final bool includeImageData;

  /// 是否保存到相册
  final bool saveToGallery;

  const CameraOptions({
    this.quality = 0.8,
    this.maxWidth,
    this.maxHeight,
    this.includeImageData = false,
    this.saveToGallery = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'quality': quality,
      'maxWidth': maxWidth,
      'maxHeight': maxHeight,
      'includeImageData': includeImageData,
      'saveToGallery': saveToGallery,
    };
  }
}

/// 原生相机插件主类
class NativeCameraPlugin {
  /// 获取平台版本信息
  Future<String?> getPlatformVersion() {
    return NativeCameraPluginPlatform.instance.getPlatformVersion();
  }

  /// 检查相机权限
  Future<bool> checkCameraPermission() {
    return NativeCameraPluginPlatform.instance.checkCameraPermission();
  }

  /// 请求相机权限
  Future<bool> requestCameraPermission() {
    return NativeCameraPluginPlatform.instance.requestCameraPermission();
  }

  /// 检查相机是否可用
  Future<bool> isCameraAvailable() {
    return NativeCameraPluginPlatform.instance.isCameraAvailable();
  }

  /// 拍照
  ///
  /// [options] 拍照配置选项
  /// 返回 [CameraResult] 包含拍照结果
  Future<CameraResult> takePicture([CameraOptions? options]) {
    return NativeCameraPluginPlatform.instance.takePicture(
      options ?? const CameraOptions(),
    );
  }
}
