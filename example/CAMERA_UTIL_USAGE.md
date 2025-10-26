# CameraUtil 工具类使用指南

## 概述

`CameraUtil` 是一个封装了 `native_camera_plugin` 所有功能的工具类，让拍照变得更加简单易用。它自动处理权限检查、错误处理、用户提示等复杂逻辑，让开发者只需要关注业务逻辑。

## 特性

- ✅ **单例模式**: 全局唯一实例，避免重复初始化
- ✅ **自动权限管理**: 自动检查和请求相机权限
- ✅ **智能错误处理**: 完善的错误处理和用户友好的提示
- ✅ **多种拍照模式**: 支持基础拍照、高质量拍照、限制尺寸拍照等
- ✅ **批量拍照**: 支持一次拍摄多张照片
- ✅ **文件管理**: 提供图片文件验证、大小获取、删除等功能
- ✅ **用户体验优化**: 自动显示权限说明对话框和操作提示

## 快速开始

### 1. 复制工具类文件

将 `utils/camera_util.dart` 文件复制到你的项目中。

### 2. 导入工具类

```dart
import 'utils/camera_util.dart';
```

### 3. 使用工具类

```dart
class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final _cameraUtil = CameraUtil.instance;
  String? _imagePath;

  Future<void> _takePicture() async {
    final result = await _cameraUtil.quickTakePicture(context: context);
    
    if (result.success) {
      setState(() {
        _imagePath = result.imagePath;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _takePicture,
            child: Text('拍照'),
          ),
          if (_imagePath != null)
            Image.file(File(_imagePath!)),
        ],
      ),
    );
  }
}
```

## API 详解

### 核心方法

#### quickTakePicture - 一键拍照（推荐）

最简单的拍照方法，自动处理所有复杂逻辑：

```dart
Future<void> _takePicture() async {
  final result = await _cameraUtil.quickTakePicture(
    context: context,           // 用于显示对话框和提示
    options: CameraOptions(     // 可选的拍照配置
      quality: 0.8,
      saveToGallery: true,
    ),
    showMessages: true,         // 是否显示操作提示
  );
  
  if (result.success) {
    print('拍照成功: ${result.imagePath}');
  } else {
    print('拍照失败: ${result.error}');
  }
}
```

#### takeHighQualityPicture - 高质量拍照

使用最高质量设置进行拍照：

```dart
final result = await _cameraUtil.takeHighQualityPicture();
```

#### takePictureWithSize - 限制尺寸拍照

限制图片的最大尺寸：

```dart
final result = await _cameraUtil.takePictureWithSize(
  maxWidth: 800,
  maxHeight: 600,
  quality: 0.8,
  includeImageData: false,
);
```

#### takeTempPicture - 临时文件拍照

拍照后不保存到相册，仅保存为临时文件：

```dart
final result = await _cameraUtil.takeTempPicture(quality: 0.6);
```

#### takeBatchPictures - 批量拍照

一次拍摄多张照片：

```dart
final results = await _cameraUtil.takeBatchPictures(
  count: 3,
  context: context,
  onProgress: (current, total) {
    print('拍照进度: $current/$total');
  },
);

int successCount = results.where((r) => r.success).length;
print('成功拍摄 $successCount 张照片');
```

### 权限管理

#### ensureCameraPermission - 确保相机权限

检查并请求相机权限：

```dart
bool hasPermission = await _cameraUtil.ensureCameraPermission(
  context: context,
  showDialog: true,  // 是否显示权限说明对话框
);

if (hasPermission) {
  // 可以进行拍照操作
} else {
  // 权限被拒绝
}
```

#### isCameraAvailable - 检查相机可用性

```dart
bool isAvailable = await _cameraUtil.isCameraAvailable();
```

### 文件管理

#### validateImageFile - 验证图片文件

```dart
bool isValid = await _cameraUtil.validateImageFile(imagePath);
```

#### getImageFileSize - 获取文件大小

```dart
int size = await _cameraUtil.getImageFileSize(imagePath);
String formattedSize = _cameraUtil.formatFileSize(size); // "1.2 MB"
```

#### deleteTempImage - 删除临时文件

```dart
bool deleted = await _cameraUtil.deleteTempImage(imagePath);
```

#### getImageFileName - 获取文件名

```dart
String fileName = _cameraUtil.getImageFileName(imagePath);
```

#### showImagePreview - 全屏图片预览

显示真正的全屏图片预览，提供沉浸式的图片查看体验：

```dart
await _cameraUtil.showImagePreview(
  context: context,
  imagePath: imagePath,
  title: '图片预览',  // 可选标题
);
```

**功能特性**:
- 🖼️ **真全屏显示**: 占据整个屏幕，无边框沉浸式体验
- 🔍 **强化缩放**: 支持 0.3x - 5x 缩放范围
- 👆 **流畅平移**: 支持图片拖拽移动，无边界限制
- 🎯 **简洁交互**: 
  - 单击屏幕：隐藏/显示UI界面
  - 双击屏幕：快速退出预览
  - 双指缩放：精确控制图片大小
- 📊 **基本信息**: 显示文件名、大小等关键信息
- 🎨 **极简设计**: 纯黑背景，最小化UI干扰，专注图片本身
- ⚡ **纯净体验**: 去除多余按钮，提供最纯粹的图片查看体验

## 使用场景

### 场景1: 简单拍照应用

```dart
class SimpleCameraApp extends StatefulWidget {
  @override
  _SimpleCameraAppState createState() => _SimpleCameraAppState();
}

class _SimpleCameraAppState extends State<SimpleCameraApp> {
  final _cameraUtil = CameraUtil.instance;
  String? _imagePath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('拍照应用')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () async {
              final result = await _cameraUtil.quickTakePicture(context: context);
              if (result.success) {
                setState(() => _imagePath = result.imagePath);
              }
            },
            child: Text('拍照'),
          ),
          if (_imagePath != null)
            Expanded(
              child: GestureDetector(
                onTap: () {
                  _cameraUtil.showImagePreview(
                    context: context,
                    imagePath: _imagePath!,
                    title: '拍照结果',
                  );
                },
                child: Image.file(File(_imagePath!)),
              ),
            ),
        ],
      ),
    );
  }
}
```

### 场景2: 多种拍照模式

```dart
class MultiModeCameraApp extends StatefulWidget {
  @override
  _MultiModeCameraAppState createState() => _MultiModeCameraAppState();
}

class _MultiModeCameraAppState extends State<MultiModeCameraApp> {
  final _cameraUtil = CameraUtil.instance;
  String? _imagePath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 基础拍照
          ElevatedButton(
            onPressed: () => _takePicture(_cameraUtil.takePicture),
            child: Text('基础拍照'),
          ),
          
          // 高质量拍照
          ElevatedButton(
            onPressed: () => _takePicture(_cameraUtil.takeHighQualityPicture),
            child: Text('高质量拍照'),
          ),
          
          // 限制尺寸拍照
          ElevatedButton(
            onPressed: () => _takePicture(() => _cameraUtil.takePictureWithSize(
              maxWidth: 800,
              maxHeight: 600,
            )),
            child: Text('限制尺寸拍照'),
          ),
          
          // 临时文件拍照
          ElevatedButton(
            onPressed: () => _takePicture(_cameraUtil.takeTempPicture),
            child: Text('临时文件拍照'),
          ),
          
          if (_imagePath != null)
            Expanded(
              child: GestureDetector(
                onTap: () {
                  _cameraUtil.showImagePreview(
                    context: context,
                    imagePath: _imagePath!,
                    title: '拍照预览',
                  );
                },
                child: Image.file(File(_imagePath!)),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _takePicture(Future<CameraResult> Function() takePhoto) async {
    final result = await takePhoto();
    if (result.success) {
      setState(() => _imagePath = result.imagePath);
    }
  }
}
```

### 场景3: 批量拍照应用

```dart
class BatchCameraApp extends StatefulWidget {
  @override
  _BatchCameraAppState createState() => _BatchCameraAppState();
}

class _BatchCameraAppState extends State<BatchCameraApp> {
  final _cameraUtil = CameraUtil.instance;
  List<String> _imagePaths = [];
  String _status = '';

  Future<void> _takeBatchPictures() async {
    setState(() => _status = '准备拍照...');
    
    final results = await _cameraUtil.takeBatchPictures(
      count: 5,
      context: context,
      onProgress: (current, total) {
        setState(() => _status = '拍照进度: $current/$total');
      },
    );

    final successPaths = results
        .where((r) => r.success)
        .map((r) => r.imagePath!)
        .toList();

    setState(() {
      _imagePaths = successPaths;
      _status = '完成！成功拍摄 ${successPaths.length} 张照片';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('批量拍照')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _takeBatchPictures,
            child: Text('拍摄5张照片'),
          ),
          Text(_status),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
              ),
              itemCount: _imagePaths.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    _cameraUtil.showImagePreview(
                      context: context,
                      imagePath: _imagePaths[index],
                      title: '批量拍照 ${index + 1}',
                    );
                  },
                  child: Image.file(File(_imagePaths[index])),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

## 最佳实践

### 1. 权限处理

总是在拍照前检查权限，工具类会自动处理，但你也可以手动检查：

```dart
// 工具类会自动处理权限，推荐使用
final result = await _cameraUtil.quickTakePicture(context: context);

// 或者手动检查权限
bool hasPermission = await _cameraUtil.ensureCameraPermission(context: context);
if (hasPermission) {
  final result = await _cameraUtil.takePicture();
}
```

### 2. 错误处理

总是检查拍照结果：

```dart
final result = await _cameraUtil.quickTakePicture(context: context);

if (result.success) {
  // 拍照成功，使用 result.imagePath
  setState(() => _imagePath = result.imagePath);
} else {
  // 拍照失败，显示错误信息
  print('拍照失败: ${result.error}');
}
```

### 3. 内存管理

对于临时文件，记得在不需要时删除：

```dart
// 拍摄临时文件
final result = await _cameraUtil.takeTempPicture();

if (result.success) {
  // 使用图片...
  
  // 不需要时删除临时文件
  await _cameraUtil.deleteTempImage(result.imagePath);
}
```

### 4. 用户体验

使用 `quickTakePicture` 方法可以提供最好的用户体验：

```dart
// 推荐：自动处理权限对话框和提示信息
final result = await _cameraUtil.quickTakePicture(
  context: context,
  showMessages: true,
);

// 不推荐：需要手动处理各种情况
bool hasPermission = await _cameraUtil.ensureCameraPermission(context: context);
if (!hasPermission) {
  // 显示权限被拒绝的提示...
  return;
}

bool isAvailable = await _cameraUtil.isCameraAvailable();
if (!isAvailable) {
  // 显示相机不可用的提示...
  return;
}

final result = await _cameraUtil.takePicture();
// 手动处理结果...
```

## 常见问题

### Q: 如何自定义权限对话框？

A: 你可以设置 `showDialog: false`，然后自己处理权限逻辑：

```dart
bool hasPermission = await _cameraUtil.ensureCameraPermission(
  context: context,
  showDialog: false,  // 不显示默认对话框
);

if (!hasPermission) {
  // 显示你自定义的权限说明
  showMyCustomPermissionDialog();
}
```

### Q: 如何获取图片的详细信息？

A: 使用工具类提供的辅助方法：

```dart
final result = await _cameraUtil.quickTakePicture(context: context);

if (result.success) {
  String fileName = _cameraUtil.getImageFileName(result.imagePath);
  int fileSize = await _cameraUtil.getImageFileSize(result.imagePath);
  String formattedSize = _cameraUtil.formatFileSize(fileSize);
  
  print('文件名: $fileName');
  print('文件大小: $formattedSize');
}
```

### Q: 如何处理批量拍照的失败情况？

A: 批量拍照会返回所有结果，你可以分别处理成功和失败的情况：

```dart
final results = await _cameraUtil.takeBatchPictures(count: 3, context: context);

List<String> successPaths = [];
List<String> errors = [];

for (var result in results) {
  if (result.success) {
    successPaths.add(result.imagePath!);
  } else {
    errors.add(result.error!);
  }
}

print('成功: ${successPaths.length} 张');
print('失败: ${errors.length} 张');
```

### Q: 如何自定义图片预览界面？

A: 图片预览功能已经内置了丰富的功能，如果需要自定义，可以参考 `showImagePreview` 方法的实现，创建自己的预览界面：

```dart
// 简单的自定义预览
void showCustomPreview(BuildContext context, String imagePath) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      child: InteractiveViewer(
        child: Image.file(File(imagePath)),
      ),
    ),
  );
}

// 使用工具类的完整预览（推荐）
_cameraUtil.showImagePreview(
  context: context,
  imagePath: imagePath,
  title: '自定义标题',
);
```

### Q: 全屏预览如何操作？

A: 全屏预览提供了多种直观的操作方式：

```dart
// 显示全屏预览
await _cameraUtil.showImagePreview(
  context: context,
  imagePath: imagePath,
  title: '全屏预览',
);
```

**操作说明**:
- **单击屏幕**: 隐藏/显示顶部UI界面，获得纯净的图片查看体验
- **双击屏幕**: 快速退出预览，返回上一页面
- **双指缩放**: 精确控制图片缩放，支持 0.3x - 5x 范围
- **拖拽移动**: 在缩放状态下可以拖拽查看图片不同部分
- **极简界面**: 专注于图片本身，最小化UI干扰

### Q: 如何自定义全屏预览的行为？

A: 你可以通过修改 `showImagePreview` 方法的参数来自定义行为，或者基于现有实现创建自己的版本：

```dart
// 使用自定义标题
await _cameraUtil.showImagePreview(
  context: context,
  imagePath: imagePath,
  title: '我的照片预览',  // 自定义标题
);

// 如果需要更多自定义，可以参考工具类的实现
// 创建自己的全屏预览组件
```

## 总结

`CameraUtil` 工具类大大简化了相机拍照的开发工作，让你可以专注于业务逻辑而不是底层的权限管理和错误处理。推荐在所有需要拍照功能的项目中使用这个工具类。
