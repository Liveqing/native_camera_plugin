package com.example.native_camera_plugin

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.media.ExifInterface
import android.net.Uri
import android.os.Environment
import android.provider.MediaStore
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.text.SimpleDateFormat
import java.util.*

/** NativeCameraPlugin */
class NativeCameraPlugin :
    FlutterPlugin,
    MethodCallHandler,
    ActivityAware,
    PluginRegistry.ActivityResultListener,
    PluginRegistry.RequestPermissionsResultListener {

    companion object {
        private const val CAMERA_REQUEST_CODE = 1001
        private const val CAMERA_PERMISSION_REQUEST_CODE = 1002
    }

    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private var context: Context? = null
    private var pendingResult: Result? = null
    private var currentPhotoPath: String? = null
    private var cameraOptions: Map<String, Any>? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "native_camera_plugin")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }
            "checkCameraPermission" -> {
                result.success(checkCameraPermission())
            }
            "requestCameraPermission" -> {
                requestCameraPermission(result)
            }
            "isCameraAvailable" -> {
                result.success(isCameraAvailable())
            }
            "takePicture" -> {
                takePicture(call, result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun checkCameraPermission(): Boolean {
        return activity?.let {
            ContextCompat.checkSelfPermission(it, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED
        } ?: false
    }

    private fun requestCameraPermission(result: Result) {
        activity?.let {
            if (checkCameraPermission()) {
                result.success(true)
            } else {
                pendingResult = result
                ActivityCompat.requestPermissions(
                    it,
                    arrayOf(Manifest.permission.CAMERA),
                    CAMERA_PERMISSION_REQUEST_CODE
                )
            }
        } ?: result.success(false)
    }

    private fun isCameraAvailable(): Boolean {
        return context?.packageManager?.hasSystemFeature(PackageManager.FEATURE_CAMERA_ANY) ?: false
    }

    private fun takePicture(call: MethodCall, result: Result) {
        if (!checkCameraPermission()) {
            result.error("PERMISSION_DENIED", "Camera permission not granted", null)
            return
        }

        if (!isCameraAvailable()) {
            result.error("CAMERA_NOT_AVAILABLE", "Camera is not available on this device", null)
            return
        }

        activity?.let { act ->
            try {
                val options = call.arguments as? Map<String, Any>
                cameraOptions = options
                pendingResult = result

                val takePictureIntent = Intent(MediaStore.ACTION_IMAGE_CAPTURE)
                
                // 创建临时文件存储照片
                val photoFile = createImageFile()
                currentPhotoPath = photoFile.absolutePath

                val photoURI = FileProvider.getUriForFile(
                    act,
                    "${act.packageName}.fileprovider",
                    photoFile
                )

                takePictureIntent.putExtra(MediaStore.EXTRA_OUTPUT, photoURI)
                act.startActivityForResult(takePictureIntent, CAMERA_REQUEST_CODE)

            } catch (e: Exception) {
                result.error("CAMERA_ERROR", "Failed to start camera: ${e.message}", null)
            }
        } ?: result.error("ACTIVITY_NOT_AVAILABLE", "Activity is not available", null)
    }

    @Throws(IOException::class)
    private fun createImageFile(): File {
        val timeStamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault()).format(Date())
        val imageFileName = "JPEG_${timeStamp}_"
        val storageDir = context?.getExternalFilesDir(Environment.DIRECTORY_PICTURES)
        return File.createTempFile(imageFileName, ".jpg", storageDir)
    }

    private fun processImage(imagePath: String): Map<String, Any> {
        try {
            val options = cameraOptions
            val quality = (options?.get("quality") as? Double)?.toFloat() ?: 0.8f
            val maxWidth = options?.get("maxWidth") as? Int
            val maxHeight = options?.get("maxHeight") as? Int
            val includeImageData = options?.get("includeImageData") as? Boolean ?: false
            val saveToGallery = options?.get("saveToGallery") as? Boolean ?: true

            // 读取原始图片
            var bitmap = BitmapFactory.decodeFile(imagePath)
            
            // 处理图片旋转
            bitmap = rotateImageIfRequired(bitmap, imagePath)

            // 调整图片尺寸
            if (maxWidth != null || maxHeight != null) {
                bitmap = resizeBitmap(bitmap, maxWidth, maxHeight)
            }

            // 保存处理后的图片
            val outputFile = if (saveToGallery) {
                saveToGallery(bitmap, quality)
            } else {
                saveTempFile(bitmap, quality)
            }

            val result = mutableMapOf<String, Any>(
                "success" to true,
                "imagePath" to outputFile.absolutePath
            )

            // 如果需要返回图片数据
            if (includeImageData) {
                val byteArrayOutputStream = ByteArrayOutputStream()
                bitmap.compress(Bitmap.CompressFormat.JPEG, (quality * 100).toInt(), byteArrayOutputStream)
                result["imageData"] = byteArrayOutputStream.toByteArray()
            }

            return result

        } catch (e: Exception) {
            return mapOf(
                "success" to false,
                "error" to "Failed to process image: ${e.message}"
            )
        }
    }

    private fun rotateImageIfRequired(bitmap: Bitmap, imagePath: String): Bitmap {
        try {
            val exif = ExifInterface(imagePath)
            val orientation = exif.getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL)
            
            return when (orientation) {
                ExifInterface.ORIENTATION_ROTATE_90 -> rotateBitmap(bitmap, 90f)
                ExifInterface.ORIENTATION_ROTATE_180 -> rotateBitmap(bitmap, 180f)
                ExifInterface.ORIENTATION_ROTATE_270 -> rotateBitmap(bitmap, 270f)
                else -> bitmap
            }
        } catch (e: Exception) {
            return bitmap
        }
    }

    private fun rotateBitmap(bitmap: Bitmap, degrees: Float): Bitmap {
        val matrix = Matrix()
        matrix.postRotate(degrees)
        return Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true)
    }

    private fun resizeBitmap(bitmap: Bitmap, maxWidth: Int?, maxHeight: Int?): Bitmap {
        val width = bitmap.width
        val height = bitmap.height

        if (maxWidth == null && maxHeight == null) return bitmap

        val targetWidth = maxWidth ?: width
        val targetHeight = maxHeight ?: height

        val scaleX = targetWidth.toFloat() / width
        val scaleY = targetHeight.toFloat() / height
        val scale = minOf(scaleX, scaleY)

        if (scale >= 1.0f) return bitmap

        val newWidth = (width * scale).toInt()
        val newHeight = (height * scale).toInt()

        return Bitmap.createScaledBitmap(bitmap, newWidth, newHeight, true)
    }

    private fun saveToGallery(bitmap: Bitmap, quality: Float): File {
        val timeStamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault()).format(Date())
        val fileName = "IMG_${timeStamp}.jpg"
        val picturesDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES)
        val appDir = File(picturesDir, "NativeCamera")
        
        if (!appDir.exists()) {
            appDir.mkdirs()
        }

        val file = File(appDir, fileName)
        val outputStream = FileOutputStream(file)
        bitmap.compress(Bitmap.CompressFormat.JPEG, (quality * 100).toInt(), outputStream)
        outputStream.close()

        // 通知媒体库更新
        context?.let {
            val mediaScanIntent = Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE)
            mediaScanIntent.data = Uri.fromFile(file)
            it.sendBroadcast(mediaScanIntent)
        }

        return file
    }

    private fun saveTempFile(bitmap: Bitmap, quality: Float): File {
        val file = File(context?.cacheDir, "temp_camera_${System.currentTimeMillis()}.jpg")
        val outputStream = FileOutputStream(file)
        bitmap.compress(Bitmap.CompressFormat.JPEG, (quality * 100).toInt(), outputStream)
        outputStream.close()
        return file
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == CAMERA_REQUEST_CODE) {
            val result = pendingResult
            pendingResult = null

            if (result != null) {
                if (resultCode == Activity.RESULT_OK) {
                    currentPhotoPath?.let { path ->
                        val processedResult = processImage(path)
                        result.success(processedResult)
                    } ?: result.error("FILE_ERROR", "Photo file path is null", null)
                } else {
                    result.error("USER_CANCELLED", "User cancelled camera operation", null)
                }
            }
            return true
        }
        return false
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ): Boolean {
        if (requestCode == CAMERA_PERMISSION_REQUEST_CODE) {
            val result = pendingResult
            pendingResult = null

            if (result != null) {
                val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
                result.success(granted)
            }
            return true
        }
        return false
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener(this)
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener(this)
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
