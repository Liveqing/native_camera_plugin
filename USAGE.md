# Native Camera Plugin 使用指南

## 快速开始

### 1. 安装插件

```bash
flutter pub add native_camera_plugin
```

### 2. 配置权限

#### Android
在 `android/app/src/main/AndroidManifest.xml` 添加：
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

#### iOS
在 `ios/Runner/Info.plist` 添加：
```xml
<key>NSCameraUsageDescription</key>
<string>需要访问相机来拍照</string>
```

### 3. 基础使用

```dart
import 'package:native_camera_plugin/native_camera_plugin.dart';

final cameraPlugin = NativeCameraPlugin();

// 检查并请求权限
if (!await cameraPlugin.checkCameraPermission()) {
  await cameraPlugin.requestCameraPermission();
}

// 拍照
final result = await cameraPlugin.takePicture();
if (result.success) {
  print('图片路径: ${result.imagePath}');
}
```

## 高级功能

### 自定义拍照选项

```dart
final result = await cameraPlugin.takePicture(
  CameraOptions(
    quality: 0.9,           // 高质量
    maxWidth: 1920,         // 限制宽度
    maxHeight: 1080,        // 限制高度
    includeImageData: true, // 返回图片数据
    saveToGallery: false,   // 不保存到相册
  ),
);
```

### 错误处理

```dart
try {
  final result = await cameraPlugin.takePicture();
  if (!result.success) {
    switch (result.error) {
      case 'PERMISSION_DENIED':
        // 处理权限被拒绝
        break;
      case 'USER_CANCELLED':
        // 用户取消拍照
        break;
      default:
        // 其他错误
        break;
    }
  }
} catch (e) {
  // 处理异常
}
```

## 最佳实践

1. **权限检查**: 每次拍照前检查权限
2. **错误处理**: 完善的错误处理机制
3. **用户体验**: 提供加载状态和错误提示
4. **性能优化**: 根据需要调整图片质量和尺寸
5. **安全考虑**: 不在日志中输出敏感信息

## 常见问题

### Q: 拍照后图片旋转了怎么办？
A: 插件会自动处理图片旋转，确保正确显示。

### Q: 如何控制图片文件大小？
A: 通过调整 `quality` 参数和 `maxWidth`/`maxHeight` 来控制。

### Q: 支持前置摄像头吗？
A: 当前版本使用系统默认相机应用，由用户选择前后摄像头。

### Q: 如何在企业环境中确保安全？
A: 插件不使用第三方库，所有数据本地处理，符合企业安全要求。
