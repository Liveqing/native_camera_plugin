import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'native_camera_plugin_method_channel.dart';
import 'native_camera_plugin.dart';

abstract class NativeCameraPluginPlatform extends PlatformInterface {
  /// Constructs a NativeCameraPluginPlatform.
  NativeCameraPluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static NativeCameraPluginPlatform _instance =
      MethodChannelNativeCameraPlugin();

  /// The default instance of [NativeCameraPluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelNativeCameraPlugin].
  static NativeCameraPluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [NativeCameraPluginPlatform] when
  /// they register themselves.
  static set instance(NativeCameraPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// 获取平台版本信息
  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  /// 检查相机权限
  Future<bool> checkCameraPermission() {
    throw UnimplementedError(
      'checkCameraPermission() has not been implemented.',
    );
  }

  /// 请求相机权限
  Future<bool> requestCameraPermission() {
    throw UnimplementedError(
      'requestCameraPermission() has not been implemented.',
    );
  }

  /// 检查相机是否可用
  Future<bool> isCameraAvailable() {
    throw UnimplementedError('isCameraAvailable() has not been implemented.');
  }

  /// 拍照
  Future<CameraResult> takePicture(CameraOptions options) {
    throw UnimplementedError('takePicture() has not been implemented.');
  }
}
