import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:native_camera_plugin/native_camera_plugin.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Native Camera Plugin Demo',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const CameraDemo(),
    );
  }
}

class CameraDemo extends StatefulWidget {
  const CameraDemo({super.key});

  @override
  State<CameraDemo> createState() => _CameraDemoState();
}

class _CameraDemoState extends State<CameraDemo> {
  final _nativeCameraPlugin = NativeCameraPlugin();

  String _platformVersion = 'Unknown';
  bool _cameraPermission = false;
  bool _cameraAvailable = false;
  String? _lastImagePath;
  Uint8List? _lastImageData;
  bool _isLoading = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _initializePlugin();
  }

  Future<void> _initializePlugin() async {
    await _getPlatformVersion();
    await _checkCameraPermission();
    await _checkCameraAvailability();
  }

  Future<void> _getPlatformVersion() async {
    try {
      final version =
          await _nativeCameraPlugin.getPlatformVersion() ?? 'Unknown';
      setState(() {
        _platformVersion = version;
      });
    } catch (e) {
      setState(() {
        _platformVersion = 'Failed to get platform version: $e';
      });
    }
  }

  Future<void> _checkCameraPermission() async {
    try {
      final hasPermission = await _nativeCameraPlugin.checkCameraPermission();
      setState(() {
        _cameraPermission = hasPermission;
      });
    } catch (e) {
      _showMessage('检查相机权限失败: $e');
    }
  }

  Future<void> _requestCameraPermission() async {
    try {
      final granted = await _nativeCameraPlugin.requestCameraPermission();
      setState(() {
        _cameraPermission = granted;
      });
      _showMessage(granted ? '相机权限已授予' : '相机权限被拒绝');
    } catch (e) {
      _showMessage('请求相机权限失败: $e');
    }
  }

  Future<void> _checkCameraAvailability() async {
    try {
      final available = await _nativeCameraPlugin.isCameraAvailable();
      setState(() {
        _cameraAvailable = available;
      });
    } catch (e) {
      _showMessage('检查相机可用性失败: $e');
    }
  }

  Future<void> _takePicture({CameraOptions? options}) async {
    if (!_cameraPermission) {
      _showMessage('请先授予相机权限');
      return;
    }

    if (!_cameraAvailable) {
      _showMessage('相机不可用');
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = '正在拍照...';
    });

    try {
      final result = await _nativeCameraPlugin.takePicture(options);

      if (result.success) {
        setState(() {
          _lastImagePath = result.imagePath;
          _lastImageData = result.imageData;
          _statusMessage = '拍照成功！';
        });
        _showMessage('拍照成功！图片路径: ${result.imagePath}');
      } else {
        _showMessage('拍照失败: ${result.error}');
        setState(() {
          _statusMessage = '拍照失败: ${result.error}';
        });
      }
    } catch (e) {
      _showMessage('拍照异常: $e');
      setState(() {
        _statusMessage = '拍照异常: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  Widget _buildImagePreview() {
    if (_lastImagePath == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.image, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('暂无图片', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Column(
        children: [
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              image: DecorationImage(
                image: FileImage(File(_lastImagePath!)),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              '图片路径: ${_lastImagePath!.split('/').last}',
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Native Camera Plugin Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 系统信息卡片
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '系统信息',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text('平台版本: $_platformVersion'),
                    Text('相机权限: ${_cameraPermission ? "已授予" : "未授予"}'),
                    Text('相机可用: ${_cameraAvailable ? "是" : "否"}'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 权限管理
            if (!_cameraPermission)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Icon(Icons.warning, color: Colors.orange, size: 48),
                      const SizedBox(height: 8),
                      const Text('需要相机权限才能使用拍照功能'),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _requestCameraPermission,
                        icon: const Icon(Icons.camera),
                        label: const Text('请求相机权限'),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // 拍照功能区域
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '拍照功能',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),

                    // 基础拍照
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : () => _takePicture(),
                        icon: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.camera_alt),
                        label: Text(_isLoading ? '拍照中...' : '基础拍照'),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // 高质量拍照
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading
                            ? null
                            : () => _takePicture(
                                options: const CameraOptions(
                                  quality: 1.0,
                                  saveToGallery: true,
                                ),
                              ),
                        icon: const Icon(Icons.high_quality),
                        label: const Text('高质量拍照'),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // 限制尺寸拍照
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading
                            ? null
                            : () => _takePicture(
                                options: const CameraOptions(
                                  quality: 0.8,
                                  maxWidth: 800,
                                  maxHeight: 600,
                                  includeImageData: true,
                                ),
                              ),
                        icon: const Icon(Icons.photo_size_select_large),
                        label: const Text('限制尺寸拍照 (800x600)'),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // 临时文件拍照
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading
                            ? null
                            : () => _takePicture(
                                options: const CameraOptions(
                                  quality: 0.6,
                                  saveToGallery: false,
                                ),
                              ),
                        icon: const Icon(Icons.folder_open),
                        label: const Text('临时文件拍照'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 状态信息
            if (_statusMessage.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.info, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_statusMessage)),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // 图片预览
            _buildImagePreview(),
          ],
        ),
      ),
    );
  }
}
