package com.example.translator

import android.Manifest
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var permissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "voxlingo/permissions",
        ).setMethodCallHandler { call, result ->
            if (call.method != "requestMicrophonePermission") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            if (checkSelfPermission(Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED) {
                result.success(true)
                return@setMethodCallHandler
            }
            if (permissionResult != null) {
                result.error("PERMISSION_REQUEST_ACTIVE", "A microphone permission request is already active.", null)
                return@setMethodCallHandler
            }
            permissionResult = result
            requestPermissions(arrayOf(Manifest.permission.RECORD_AUDIO), microphonePermissionRequest)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != microphonePermissionRequest) return
        val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
        permissionResult?.success(granted)
        permissionResult = null
    }

    companion object {
        private const val microphonePermissionRequest = 4107
    }
}
