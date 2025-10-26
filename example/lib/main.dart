import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:native_camera_plugin/native_camera_plugin.dart';
import 'utils/camera_util.dart';
import 'simple_camera_example.dart';

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
  final _cameraUtil = CameraUtil.instance;
  final _nativeCameraPlugin = NativeCameraPlugin();

  String _platformVersion = 'Unknown';
  bool _cameraPermission = false;
  bool _cameraAvailable = false;
  String? _lastImagePath;
  bool _isLoading = false;
  String _statusMessage = '';
  int _lastImageSize = 0;

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
      final granted = await _cameraUtil.ensureCameraPermission(
        context: context,
        showDialog: true,
      );
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
      final available = await _cameraUtil.isCameraAvailable();
      setState(() {
        _cameraAvailable = available;
      });
    } catch (e) {
      _showMessage('检查相机可用性失败: $e');
    }
  }

  Future<void> _takePicture({CameraOptions? options}) async {
    setState(() {
      _isLoading = true;
      _statusMessage = '正在拍照...';
    });

    try {
      final result = await _cameraUtil.quickTakePicture(
        context: context,
        options: options,
        showMessages: false, // 我们自己处理消息显示
      );

      if (result.success) {
        // 获取图片文件大小
        final fileSize = await _cameraUtil.getImageFileSize(result.imagePath);

        setState(() {
          _lastImagePath = result.imagePath;
          _lastImageSize = fileSize;
          _statusMessage = '拍照成功！文件大小: ${_cameraUtil.formatFileSize(fileSize)}';
        });
        _showMessage(
          '拍照成功！图片路径: ${_cameraUtil.getImageFileName(result.imagePath)}',
        );
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

  Future<void> _takeBatchPictures() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '准备批量拍照...';
    });

    try {
      final results = await _cameraUtil.takeBatchPictures(
        count: 3,
        context: context,
        onProgress: (current, total) {
          setState(() {
            _statusMessage = '正在拍照: $current/$total';
          });
        },
      );

      int successCount = results.where((r) => r.success).length;
      int failCount = results.length - successCount;

      // 显示最后一张成功的照片
      final lastSuccess = results.lastWhere(
        (r) => r.success,
        orElse: () => CameraResult.error('无成功照片'),
      );

      if (lastSuccess.success) {
        final fileSize = await _cameraUtil.getImageFileSize(
          lastSuccess.imagePath,
        );
        setState(() {
          _lastImagePath = lastSuccess.imagePath;
          _lastImageSize = fileSize;
        });
      }

      setState(() {
        _statusMessage = '批量拍照完成！成功: $successCount 张，失败: $failCount 张';
      });

      _showMessage('批量拍照完成！成功拍摄 $successCount 张照片');
    } catch (e) {
      _showMessage('批量拍照异常: $e');
      setState(() {
        _statusMessage = '批量拍照异常: $e';
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
          GestureDetector(
            onTap: () {
              _cameraUtil.showImagePreview(
                context: context,
                imagePath: _lastImagePath!,
                title: '拍照预览',
              );
            },
            child: Container(
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
              child: Stack(
                children: [
                  // 添加一个半透明的点击提示
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.zoom_in, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text(
                            '点击查看',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '文件名: ${_cameraUtil.getImageFileName(_lastImagePath)}',
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_lastImageSize > 0)
                  Text(
                    '文件大小: ${_cameraUtil.formatFileSize(_lastImageSize)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
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
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SimpleCameraExample(),
                ),
              );
            },
            icon: const Icon(Icons.lightbulb_outline),
            tooltip: '查看简单示例',
          ),
        ],
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

                    const SizedBox(height: 8),

                    // 批量拍照
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _takeBatchPictures,
                        icon: const Icon(Icons.burst_mode),
                        label: const Text('批量拍照 (3张)'),
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
