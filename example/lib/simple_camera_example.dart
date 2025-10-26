import 'package:flutter/material.dart';
import 'package:native_camera_plugin/native_camera_plugin.dart';
import 'utils/camera_util.dart';
import 'dart:io';

/// 简单的相机使用示例
///
/// 演示如何使用 CameraUtil 工具类进行拍照
class SimpleCameraExample extends StatefulWidget {
  const SimpleCameraExample({super.key});

  @override
  State<SimpleCameraExample> createState() => _SimpleCameraExampleState();
}

class _SimpleCameraExampleState extends State<SimpleCameraExample> {
  final _cameraUtil = CameraUtil.instance;
  String? _imagePath;
  bool _isLoading = false;

  /// 一键拍照 - 最简单的使用方式
  Future<void> _quickTakePicture() async {
    setState(() => _isLoading = true);

    final result = await _cameraUtil.quickTakePicture(context: context);

    if (result.success) {
      setState(() => _imagePath = result.imagePath);
    }

    setState(() => _isLoading = false);
  }

  /// 高质量拍照
  Future<void> _takeHighQualityPicture() async {
    setState(() => _isLoading = true);

    final result = await _cameraUtil.takeHighQualityPicture();

    if (result.success && mounted) {
      setState(() => _imagePath = result.imagePath);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('高质量照片拍摄成功！')));
    }

    setState(() => _isLoading = false);
  }

  /// 限制尺寸拍照
  Future<void> _takePictureWithSize() async {
    setState(() => _isLoading = true);

    final result = await _cameraUtil.takePictureWithSize(
      maxWidth: 800,
      maxHeight: 600,
      quality: 0.8,
    );

    if (result.success && mounted) {
      setState(() => _imagePath = result.imagePath);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('限制尺寸照片拍摄成功！')));
    }

    setState(() => _isLoading = false);
  }

  /// 临时文件拍照
  Future<void> _takeTempPicture() async {
    setState(() => _isLoading = true);

    final result = await _cameraUtil.takeTempPicture();

    if (result.success && mounted) {
      setState(() => _imagePath = result.imagePath);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('临时照片拍摄成功！（未保存到相册）')));
    }

    setState(() => _isLoading = false);
  }

  /// 自定义配置拍照
  Future<void> _takeCustomPicture() async {
    setState(() => _isLoading = true);

    // 自定义配置
    const options = CameraOptions(
      quality: 0.9,
      maxWidth: 1200,
      maxHeight: 1200,
      saveToGallery: true,
      includeImageData: false,
    );

    final result = await _cameraUtil.takePictureWithOptions(options);

    if (result.success && mounted) {
      setState(() => _imagePath = result.imagePath);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('自定义配置照片拍摄成功！')));
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('简单相机示例'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 说明文字
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '相机工具类使用示例',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '这个示例展示了如何使用 CameraUtil 工具类进行拍照。'
                      '工具类已经封装了权限检查、错误处理等功能，'
                      '让拍照变得非常简单。',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 拍照按钮组
            Expanded(
              child: Column(
                children: [
                  // 一键拍照 - 推荐使用
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _quickTakePicture,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.camera_alt),
                      label: Text(_isLoading ? '拍照中...' : '一键拍照（推荐）'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 其他拍照选项
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : _takeHighQualityPicture,
                          child: const Text('高质量'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _takePictureWithSize,
                          child: const Text('限制尺寸'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _takeTempPicture,
                          child: const Text('临时文件'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _takeCustomPicture,
                          child: const Text('自定义配置'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 图片预览
                  Expanded(child: _buildImagePreview()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_imagePath == null) {
      return Card(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32.0),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                '拍照后图片将显示在这里',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                _cameraUtil.showImagePreview(
                  context: context,
                  imagePath: _imagePath!,
                  title: '拍照结果',
                );
              },
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  image: DecorationImage(
                    image: FileImage(File(_imagePath!)),
                    fit: BoxFit.contain,
                  ),
                ),
                child: Stack(
                  children: [
                    // 添加点击提示
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.fullscreen,
                              color: Colors.white,
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              '点击放大',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                const Icon(Icons.photo, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _cameraUtil.getImageFileName(_imagePath),
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
