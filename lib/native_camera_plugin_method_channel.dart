import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'native_camera_plugin_platform_interface.dart';
import 'native_camera_plugin.dart';

/// An implementation of [NativeCameraPluginPlatform] that uses method channels.
class MethodChannelNativeCameraPlugin extends NativeCameraPluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('native_camera_plugin');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }

  @override
  Future<bool> checkCameraPermission() async {
    try {
      final result = await methodChannel.invokeMethod<bool>(
        'checkCameraPermission',
      );
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Error checking camera permission: ${e.message}');
      return false;
    }
  }

  @override
  Future<bool> requestCameraPermission() async {
    try {
      final result = await methodChannel.invokeMethod<bool>(
        'requestCameraPermission',
      );
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Error requesting camera permission: ${e.message}');
      return false;
    }
  }

  @override
  Future<bool> isCameraAvailable() async {
    try {
      final result = await methodChannel.invokeMethod<bool>(
        'isCameraAvailable',
      );
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Error checking camera availability: ${e.message}');
      return false;
    }
  }

  @override
  Future<CameraResult> takePicture(CameraOptions options) async {
    try {
      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>(
        'takePicture',
        options.toMap(),
      );

      if (result == null) {
        return CameraResult.error('No result returned from native platform');
      }

      final success = result['success'] as bool? ?? false;

      if (!success) {
        final error = result['error'] as String? ?? 'Unknown error occurred';
        return CameraResult.error(error);
      }

      final imagePath = result['imagePath'] as String?;
      final imageDataList = result['imageData'] as List<int>?;
      final imageData = imageDataList != null
          ? Uint8List.fromList(imageDataList)
          : null;

      return CameraResult.success(imagePath: imagePath, imageData: imageData);
    } on PlatformException catch (e) {
      return CameraResult.error('Platform error: ${e.message}');
    } catch (e) {
      return CameraResult.error('Unexpected error: $e');
    }
  }
}
