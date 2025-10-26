import 'dart:io';
import 'package:flutter/material.dart';
import 'package:native_camera_plugin/native_camera_plugin.dart';

/// 相机工具类
///
/// 封装了所有相机相关的操作，提供简单易用的API
/// 包括权限管理、拍照功能、错误处理等
class CameraUtil {
  static final CameraUtil _instance = CameraUtil._internal();
  factory CameraUtil() => _instance;
  CameraUtil._internal();

  final NativeCameraPlugin _cameraPlugin = NativeCameraPlugin();

  /// 获取单例实例
  static CameraUtil get instance => _instance;

  /// 检查并请求相机权限
  ///
  /// 返回 true 表示已获得权限，false 表示权限被拒绝
  /// [showDialog] 是否显示权限说明对话框
  Future<bool> ensureCameraPermission({
    BuildContext? context,
    bool showDialog = true,
  }) async {
    try {
      // 先检查是否已有权限
      bool hasPermission = await _cameraPlugin.checkCameraPermission();
      if (hasPermission) {
        return true;
      }

      // 如果需要显示对话框说明
      if (context != null && showDialog) {
        bool? shouldRequest = await _showPermissionDialog(context);
        if (shouldRequest != true) {
          return false;
        }
      }

      // 请求权限
      hasPermission = await _cameraPlugin.requestCameraPermission();
      return hasPermission;
    } catch (e) {
      debugPrint('检查相机权限失败: $e');
      return false;
    }
  }

  /// 检查相机是否可用
  Future<bool> isCameraAvailable() async {
    try {
      return await _cameraPlugin.isCameraAvailable();
    } catch (e) {
      debugPrint('检查相机可用性失败: $e');
      return false;
    }
  }

  /// 基础拍照功能
  ///
  /// 使用默认配置进行拍照
  /// 返回拍照结果，包含图片路径和可能的错误信息
  Future<CameraResult> takePicture() async {
    return await _takePictureWithOptions(const CameraOptions());
  }

  /// 高质量拍照
  ///
  /// 使用最高质量设置拍照，并保存到相册
  Future<CameraResult> takeHighQualityPicture() async {
    return await _takePictureWithOptions(
      const CameraOptions(quality: 1.0, saveToGallery: true),
    );
  }

  /// 限制尺寸拍照
  ///
  /// [maxWidth] 最大宽度
  /// [maxHeight] 最大高度
  /// [quality] 图片质量 (0.0 - 1.0)
  /// [includeImageData] 是否返回图片数据
  Future<CameraResult> takePictureWithSize({
    int? maxWidth,
    int? maxHeight,
    double quality = 0.8,
    bool includeImageData = false,
  }) async {
    return await _takePictureWithOptions(
      CameraOptions(
        quality: quality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        includeImageData: includeImageData,
        saveToGallery: true,
      ),
    );
  }

  /// 临时文件拍照
  ///
  /// 拍照后不保存到相册，仅保存为临时文件
  /// [quality] 图片质量 (0.0 - 1.0)
  Future<CameraResult> takeTempPicture({double quality = 0.6}) async {
    return await _takePictureWithOptions(
      CameraOptions(quality: quality, saveToGallery: false),
    );
  }

  /// 自定义配置拍照
  ///
  /// [options] 自定义的拍照配置选项
  Future<CameraResult> takePictureWithOptions(CameraOptions options) async {
    return await _takePictureWithOptions(options);
  }

  /// 一键拍照
  ///
  /// 自动处理权限检查、相机可用性检查，然后拍照
  /// [context] 用于显示提示信息的上下文
  /// [options] 拍照配置选项，如果不提供则使用默认配置
  /// [showMessages] 是否显示操作提示信息
  Future<CameraResult> quickTakePicture({
    BuildContext? context,
    CameraOptions? options,
    bool showMessages = true,
  }) async {
    try {
      // 检查并请求权限
      bool hasPermission = await ensureCameraPermission(
        context: context,
        showDialog: true,
      );

      if (!hasPermission) {
        if (context != null && showMessages) {
          _showMessage(context, '相机权限被拒绝，无法拍照');
        }
        return CameraResult.error('PERMISSION_DENIED');
      }

      // 检查相机可用性
      bool isAvailable = await isCameraAvailable();
      if (!isAvailable) {
        if (context != null && showMessages) {
          _showMessage(context, '相机不可用，请检查设备');
        }
        return CameraResult.error('CAMERA_NOT_AVAILABLE');
      }

      // 拍照
      final result = await _takePictureWithOptions(
        options ?? const CameraOptions(),
      );

      // 显示结果提示
      if (context != null && showMessages) {
        if (result.success) {
          _showMessage(context, '拍照成功！');
        } else {
          _showMessage(context, '拍照失败: ${result.error}');
        }
      }

      return result;
    } catch (e) {
      debugPrint('一键拍照失败: $e');
      if (context != null && showMessages) {
        _showMessage(context, '拍照异常: $e');
      }
      return CameraResult.error('UNKNOWN_ERROR: $e');
    }
  }

  /// 批量拍照
  ///
  /// [count] 拍照数量
  /// [options] 拍照配置选项
  /// [context] 用于显示进度的上下文
  /// [onProgress] 进度回调函数
  Future<List<CameraResult>> takeBatchPictures({
    required int count,
    CameraOptions? options,
    BuildContext? context,
    Function(int current, int total)? onProgress,
  }) async {
    List<CameraResult> results = [];

    // 先检查权限和相机可用性
    bool hasPermission = await ensureCameraPermission(context: context);
    if (!hasPermission) {
      return List.generate(
        count,
        (_) => CameraResult.error('PERMISSION_DENIED'),
      );
    }

    bool isAvailable = await isCameraAvailable();
    if (!isAvailable) {
      return List.generate(
        count,
        (_) => CameraResult.error('CAMERA_NOT_AVAILABLE'),
      );
    }

    // 批量拍照
    for (int i = 0; i < count; i++) {
      onProgress?.call(i + 1, count);

      final result = await _takePictureWithOptions(
        options ?? const CameraOptions(),
      );
      results.add(result);

      // 如果拍照失败，询问是否继续
      if (!result.success && context != null) {
        bool? shouldContinue = await _showContinueDialog(
          context,
          '第${i + 1}张照片拍照失败: ${result.error}\n是否继续拍摄剩余照片？',
        );
        if (shouldContinue != true) {
          break;
        }
      }

      // 添加短暂延迟，避免连续拍照过快
      if (i < count - 1) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    return results;
  }

  /// 验证图片文件是否存在且有效
  ///
  /// [imagePath] 图片文件路径
  Future<bool> validateImageFile(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) {
      return false;
    }

    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        return false;
      }

      final stat = await file.stat();
      return stat.size > 0;
    } catch (e) {
      debugPrint('验证图片文件失败: $e');
      return false;
    }
  }

  /// 获取图片文件大小
  ///
  /// [imagePath] 图片文件路径
  /// 返回文件大小（字节），如果文件不存在返回0
  Future<int> getImageFileSize(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) {
      return 0;
    }

    try {
      final file = File(imagePath);
      if (await file.exists()) {
        final stat = await file.stat();
        return stat.size;
      }
    } catch (e) {
      debugPrint('获取图片文件大小失败: $e');
    }
    return 0;
  }

  /// 删除临时图片文件
  ///
  /// [imagePath] 图片文件路径
  Future<bool> deleteTempImage(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) {
      return false;
    }

    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
    } catch (e) {
      debugPrint('删除临时图片失败: $e');
    }
    return false;
  }

  /// 内部拍照方法
  Future<CameraResult> _takePictureWithOptions(CameraOptions options) async {
    try {
      return await _cameraPlugin.takePicture(options);
    } catch (e) {
      debugPrint('拍照失败: $e');
      return CameraResult.error('CAMERA_ERROR: $e');
    }
  }

  /// 显示权限说明对话框
  Future<bool?> _showPermissionDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.camera_alt, color: Colors.blue),
              SizedBox(width: 8),
              Text('相机权限'),
            ],
          ),
          content: const Text(
            '应用需要访问相机来拍照。\n\n'
            '请在接下来的权限请求中选择"允许"，'
            '以便正常使用拍照功能。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  /// 显示继续确认对话框
  Future<bool?> _showContinueDialog(
    BuildContext context,
    String message,
  ) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('提示'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('停止'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('继续'),
            ),
          ],
        );
      },
    );
  }

  /// 显示图片预览对话框
  ///
  /// [context] 上下文
  /// [imagePath] 图片路径
  /// [title] 对话框标题
  Future<void> showImagePreview({
    required BuildContext context,
    required String imagePath,
    String? title,
  }) async {
    if (!await validateImageFile(imagePath)) {
      _showMessage(context, '图片文件不存在或已损坏');
      return;
    }

    final fileSize = await getImageFileSize(imagePath);
    final fileName = getImageFileName(imagePath);

    await showDialog(
      context: context,
      barrierDismissible: true,
      useSafeArea: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            bool showUI = true;

            return Scaffold(
              backgroundColor: Colors.black,
              body: GestureDetector(
                onTap: () {
                  setState(() {
                    showUI = !showUI;
                  });
                },
                onDoubleTap: () {
                  Navigator.of(context).pop();
                },
                child: Stack(
                  children: [
                    // 全屏图片显示区域
                    Positioned.fill(
                      child: InteractiveViewer(
                        panEnabled: true,
                        boundaryMargin: EdgeInsets.zero,
                        minScale: 0.3,
                        maxScale: 5.0,
                        child: Center(
                          child: Image.file(
                            File(imagePath),
                            fit: BoxFit.contain,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: Colors.white,
                                      size: 64,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      '图片加载失败',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                    // 顶部信息栏
                    if (showUI)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.7),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: SafeArea(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        title ?? '图片预览',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        fileName,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (fileSize > 0)
                                        Text(
                                          formatFileSize(fileSize),
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// 显示提示消息
  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }
}

/// 相机工具类扩展方法
extension CameraUtilExtension on CameraUtil {
  /// 格式化文件大小
  String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// 获取图片文件名
  String getImageFileName(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return '';
    }
    return imagePath.split('/').last;
  }
}
