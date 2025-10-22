# Native Camera Plugin

一个安全、高性能的Flutter原生相机插件，专为企业级应用设计。该插件直接使用Flutter与原生平台通信，不依赖第三方库，确保最高的安全性和性能。

## 特性

- ✅ **原生体验**: 直接调用系统相机，提供最佳用户体验
- ✅ **企业级安全**: 不使用第三方库，降低安全风险
- ✅ **跨平台支持**: 支持Android和iOS平台
- ✅ **权限管理**: 完整的相机权限检查和请求功能
- ✅ **图片处理**: 支持图片压缩、尺寸调整、旋转校正
- ✅ **灵活配置**: 丰富的拍照选项配置
- ✅ **错误处理**: 完善的错误处理和用户反馈

## 安装

在 `pubspec.yaml` 文件中添加依赖：

```yaml
dependencies:
  native_camera_plugin: ^1.0.0
```

然后运行：

```bash
flutter pub get
```

## 平台配置

### Android 配置

在 `android/app/src/main/AndroidManifest.xml` 中添加权限：

```xml
<!-- 相机权限 -->
<uses-permission android:name="android.permission.CAMERA" />
<!-- 写入外部存储权限 -->
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<!-- 读取外部存储权限 -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />

<!-- 相机硬件特性 -->
<uses-feature android:name="android.hardware.camera" android:required="false" />
<uses-feature android:name="android.hardware.camera.autofocus" android:required="false" />
```

在 `application` 标签内添加 FileProvider：

```xml
<provider
    android:name="androidx.core.content.FileProvider"
    android:authorities="${applicationId}.fileprovider"
    android:exported="false"
    android:grantUriPermissions="true">
    <meta-data
        android:name="android.support.FILE_PROVIDER_PATHS"
        android:resource="@xml/file_paths" />
</provider>
```

创建 `android/app/src/main/res/xml/file_paths.xml`：

```xml
<?xml version="1.0" encoding="utf-8"?>
<paths xmlns:android="http://schemas.android.com/apk/res/android">
    <external-files-path name="my_images" path="Pictures" />
    <external-path name="external_files" path="." />
    <cache-path name="cache" path="." />
</paths>
```

### iOS 配置

在 `ios/Runner/Info.plist` 中添加权限描述：

```xml
<!-- 相机权限描述 -->
<key>NSCameraUsageDescription</key>
<string>This app needs access to camera to take photos</string>
<!-- 相册权限描述 -->
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs access to photo library to save photos</string>
<!-- 相册添加权限描述 -->
<key>NSPhotoLibraryAddUsageDescription</key>
<string>This app needs access to photo library to save photos</string>
```

## 使用方法

### 基础使用

```dart
import 'package:native_camera_plugin/native_camera_plugin.dart';

class CameraExample extends StatefulWidget {
  @override
  _CameraExampleState createState() => _CameraExampleState();
}

class _CameraExampleState extends State<CameraExample> {
  final _cameraPlugin = NativeCameraPlugin();

  Future<void> _takePicture() async {
    // 检查相机权限
    bool hasPermission = await _cameraPlugin.checkCameraPermission();
    if (!hasPermission) {
      hasPermission = await _cameraPlugin.requestCameraPermission();
      if (!hasPermission) {
        print('相机权限被拒绝');
        return;
      }
    }

    // 检查相机是否可用
    bool isAvailable = await _cameraPlugin.isCameraAvailable();
    if (!isAvailable) {
      print('相机不可用');
      return;
    }

    // 拍照
    final result = await _cameraPlugin.takePicture();
    if (result.success) {
      print('拍照成功: ${result.imagePath}');
    } else {
      print('拍照失败: ${result.error}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('相机示例')),
      body: Center(
        child: ElevatedButton(
          onPressed: _takePicture,
          child: Text('拍照'),
        ),
      ),
    );
  }
}
```

### 高级配置

```dart
// 高质量拍照
final result = await _cameraPlugin.takePicture(
  CameraOptions(
    quality: 1.0,           // 图片质量 (0.0 - 1.0)
    saveToGallery: true,    // 保存到相册
  ),
);

// 限制图片尺寸
final result = await _cameraPlugin.takePicture(
  CameraOptions(
    quality: 0.8,
    maxWidth: 800,          // 最大宽度
    maxHeight: 600,         // 最大高度
    includeImageData: true, // 返回图片数据
  ),
);

// 临时文件拍照
final result = await _cameraPlugin.takePicture(
  CameraOptions(
    quality: 0.6,
    saveToGallery: false,   // 不保存到相册，仅临时文件
  ),
);
```

## API 参考

### NativeCameraPlugin

主要的插件类，提供所有相机功能。

#### 方法

##### `Future<String?> getPlatformVersion()`

获取平台版本信息。

**返回值**: 平台版本字符串

##### `Future<bool> checkCameraPermission()`

检查是否已授予相机权限。

**返回值**: `true` 如果已授予权限，否则 `false`

##### `Future<bool> requestCameraPermission()`

请求相机权限。

**返回值**: `true` 如果用户授予权限，否则 `false`

##### `Future<bool> isCameraAvailable()`

检查设备是否有可用的相机。

**返回值**: `true` 如果相机可用，否则 `false`

##### `Future<CameraResult> takePicture([CameraOptions? options])`

拍照功能。

**参数**:
- `options`: 可选的拍照配置选项

**返回值**: `CameraResult` 对象，包含拍照结果

### CameraOptions

拍照配置选项类。

#### 属性

- `quality` (double): 图片质量，范围 0.0 - 1.0，默认 0.8
- `maxWidth` (int?): 最大宽度，可选
- `maxHeight` (int?): 最大高度，可选
- `includeImageData` (bool): 是否返回图片数据，默认 false
- `saveToGallery` (bool): 是否保存到相册，默认 true

### CameraResult

拍照结果类。

#### 属性

- `success` (bool): 是否成功
- `imagePath` (String?): 图片文件路径
- `imageData` (Uint8List?): 图片数据（如果 `includeImageData` 为 true）
- `error` (String?): 错误信息（如果失败）

#### 工厂方法

- `CameraResult.success({String? imagePath, Uint8List? imageData})`: 创建成功结果
- `CameraResult.error(String error)`: 创建错误结果

## 错误处理

插件提供了完善的错误处理机制：

```dart
try {
  final result = await _cameraPlugin.takePicture();
  if (result.success) {
    // 处理成功结果
    print('图片路径: ${result.imagePath}');
  } else {
    // 处理错误
    print('拍照失败: ${result.error}');
  }
} catch (e) {
  // 处理异常
  print('发生异常: $e');
}
```

### 常见错误码

- `PERMISSION_DENIED`: 相机权限被拒绝
- `CAMERA_NOT_AVAILABLE`: 相机不可用
- `USER_CANCELLED`: 用户取消了拍照操作
- `FILE_ERROR`: 文件操作错误
- `IMAGE_ERROR`: 图片处理错误

## 安全特性

1. **无第三方依赖**: 直接使用Flutter和原生平台API，避免第三方库的安全风险
2. **权限控制**: 严格的权限检查和请求流程
3. **数据安全**: 图片数据在本地处理，不上传到任何服务器
4. **文件安全**: 使用系统推荐的文件存储方式
5. **内存管理**: 自动处理图片内存，避免内存泄漏

## 性能优化

1. **图片压缩**: 支持自定义压缩质量，减少文件大小
2. **尺寸控制**: 可限制图片最大尺寸，节省存储空间
3. **旋转校正**: 自动处理图片旋转，确保正确显示
4. **异步处理**: 所有操作都是异步的，不阻塞UI线程

## 兼容性

- **Flutter**: >= 2.5.0
- **Dart**: >= 2.17.0
- **Android**: API 21+ (Android 5.0+)
- **iOS**: 13.0+

## 示例应用

查看 `example` 目录中的完整示例应用，演示了所有功能的使用方法。

运行示例：

```bash
cd example
flutter run
```

## 贡献

欢迎提交 Issue 和 Pull Request 来改进这个插件。

## 许可证

MIT License

## 更新日志

### 1.0.0
- 初始版本发布
- 支持Android和iOS平台
- 基础拍照功能
- 权限管理
- 图片处理功能
- 完整的错误处理

## 支持

如果您在使用过程中遇到问题，请：

1. 查看本文档的常见问题部分
2. 查看示例应用的实现
3. 在GitHub上提交Issue

---

**注意**: 这是一个企业级安全插件，专为对安全性有高要求的应用设计。所有功能都经过严格测试，确保在生产环境中的稳定性和安全性。

