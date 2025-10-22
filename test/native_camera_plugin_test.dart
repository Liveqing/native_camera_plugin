import 'package:flutter_test/flutter_test.dart';
import 'package:native_camera_plugin/native_camera_plugin.dart';
import 'package:native_camera_plugin/native_camera_plugin_platform_interface.dart';
import 'package:native_camera_plugin/native_camera_plugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockNativeCameraPluginPlatform
    with MockPlatformInterfaceMixin
    implements NativeCameraPluginPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final NativeCameraPluginPlatform initialPlatform = NativeCameraPluginPlatform.instance;

  test('$MethodChannelNativeCameraPlugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelNativeCameraPlugin>());
  });

  test('getPlatformVersion', () async {
    NativeCameraPlugin nativeCameraPlugin = NativeCameraPlugin();
    MockNativeCameraPluginPlatform fakePlatform = MockNativeCameraPluginPlatform();
    NativeCameraPluginPlatform.instance = fakePlatform;

    expect(await nativeCameraPlugin.getPlatformVersion(), '42');
  });
}
