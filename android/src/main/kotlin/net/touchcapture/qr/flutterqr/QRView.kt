package net.touchcapture.qr.flutterqr

import android.Manifest
import android.app.Activity
import android.app.Application
import android.content.Context
import android.content.pm.PackageManager
import android.content.pm.PackageManager.PERMISSION_GRANTED
import android.graphics.Bitmap
import android.os.Build
import android.os.Bundle
import android.view.View
import com.google.zxing.ResultPoint
import android.hardware.Camera.CameraInfo
import android.util.Base64;
import com.journeyapps.barcodescanner.BarcodeCallback
import com.journeyapps.barcodescanner.BarcodeResult
import com.journeyapps.barcodescanner.BarcodeView
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugin.platform.PlatformView
import java.io.ByteArrayOutputStream
import com.google.zxing.common.PerspectiveTransform ;
import com.google.zxing.PlanarYUVLuminanceSource;

class QRView(private val registrar: PluginRegistry.Registrar, id: Int) :
        PlatformView,MethodChannel.MethodCallHandler {

    companion object {
        const val CAMERA_REQUEST_ID = 513469796
    }

    var barcodeView: BarcodeView? = null
    private val activity = registrar.activity()
    var cameraPermissionContinuation: Runnable? = null
    var requestingPermission = false
    private var isTorchOn: Boolean = false
    val channel: MethodChannel

    init {
        registrar.addRequestPermissionsResultListener(CameraRequestPermissionsListener())
        channel = MethodChannel(registrar.messenger(), "net.touchcapture.qr.flutterqr/qrview_$id")
        channel.setMethodCallHandler(this)
        checkAndRequestPermission(null)
        //updateCameraSize()
        registrar.activity().application.registerActivityLifecycleCallbacks(object : Application.ActivityLifecycleCallbacks {
            override fun onActivityPaused(p0: Activity?) {
                if (p0 == registrar.activity()) {
                    barcodeView?.pause()
                }
            }

            override fun onActivityResumed(p0: Activity?) {
                if (p0 == registrar.activity()) {
                    barcodeView?.resume()
                    //updateCameraSize()
                }
            }

            override fun onActivityStarted(p0: Activity?) {
            }

            override fun onActivityDestroyed(p0: Activity?) {
            }

            override fun onActivitySaveInstanceState(p0: Activity?, p1: Bundle?) {
            }

            override fun onActivityStopped(p0: Activity?) {
            }

            override fun onActivityCreated(p0: Activity?, p1: Bundle?) {
            }
        })
    }

    fun flipCamera() {
        barcodeView?.pause()
        var settings = barcodeView?.cameraSettings

        if(settings?.requestedCameraId == CameraInfo.CAMERA_FACING_FRONT)
            settings?.requestedCameraId = CameraInfo.CAMERA_FACING_BACK
        else
            settings?.requestedCameraId = CameraInfo.CAMERA_FACING_FRONT

        barcodeView?.cameraSettings = settings
        barcodeView?.resume()
    }

    private fun toggleFlash() {
        if (hasFlash()) {
            barcodeView?.setTorch(!isTorchOn)
            isTorchOn = !isTorchOn
        }

    }

    private fun pauseCamera() {
        if (barcodeView!!.isPreviewActive) {
            barcodeView?.pause()
        }
    }

    private fun resumeCamera() {
        if (!barcodeView!!.isPreviewActive) {
            barcodeView?.resume()
        }
    }

    private fun hasFlash(): Boolean {
        return registrar.activeContext().packageManager
                .hasSystemFeature(PackageManager.FEATURE_CAMERA_FLASH)
    }

    override fun getView(): View {
        return initBarCodeView()?.apply {
            resume()
        }!!
    }

    private fun initBarCodeView(): BarcodeView? {
        if (barcodeView == null) {
            barcodeView = createBarCodeView()
        }
        return barcodeView
    }

    private fun createBarCodeView(): BarcodeView? {
        val barcode = BarcodeView(registrar.activity())
        barcode.decodeContinuous(
                object : BarcodeCallback {
                    override fun barcodeResult(result: BarcodeResult) {
                        //updateCameraSize()
                        channel.invokeMethod("onRecognizeQR", result.text)
                        channel.invokeMethod("onResultPoints", result.resultPoints.map { it -> it.toString()})
                        channel.invokeMethod("onFramingRect", barcode.getFramingRect().flattenToString())
                        channel.invokeMethod("onTransformedResultPoints", result.getTransformedResultPoints().map { it -> it.toString()})
                        channel.invokeMethod("onBitmap", bitmapToString(result.getBitmap()))
                        channel.invokeMethod("onBitmapWithResultPoints", bitmapToString(result.getBitmapWithResultPoints(0xFF0000AA.toInt())))
                        // channel.invokeMethod("onPerspectiveTransformQ2Q",PerspectiveTransform.quadrilateralToQuadrilateral(
                        //     3.5f,
                        //     3.5f,
                        //     dimMinusThree,
                        //     3.5f,
                        //     sourceBottomRightX,
                        //     sourceBottomRightY,
                        //     3.5f,
                        //     dimMinusThree,
                        //     result.resultPoints[1].getX(),
                        //     result.resultPoints[1].getY(),
                        //     result.resultPoints[2].getX(),
                        //     result.resultPoints[2].getY(),
                        //     result.resultPoints[3].getX(),
                        //     result.resultPoints[3].getY(),
                        //     result.resultPoints[0].getX(),
                        //     result.resultPoints[0].getY());
                        // )
                        channel.invokeMethod("onQRLuminanceSourceWidth", (result.source as PlanarYUVLuminanceSource).dataWidth.toString());
                        channel.invokeMethod("onQRLuminanceSourceHeight", (result.source as PlanarYUVLuminanceSource).dataHeight.toString());
                    }

                    override fun possibleResultPoints(resultPoints: List<ResultPoint>) {}
                }
        )
        return barcode
    }

    override fun dispose() {
        barcodeView?.pause()
        barcodeView = null
    }

    private inner class CameraRequestPermissionsListener : PluginRegistry.RequestPermissionsResultListener {
        override fun onRequestPermissionsResult(id: Int, permissions: Array<String>, grantResults: IntArray): Boolean {
            if (id == CAMERA_REQUEST_ID && grantResults[0] == PERMISSION_GRANTED) {
                cameraPermissionContinuation?.run()
                return true
            }
            return false
        }
    }

    private fun hasCameraPermission(): Boolean {
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.M ||
                activity.checkSelfPermission(Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED
    }

    // private fun updateCameraSize() {
    //     channel.invokeMethod("onCameraWidthUpdated",barcodeView?.getSize()?.width?.toString() )
    //     channel.invokeMethod("onCameraHeightUpdated",barcodeView?.getSize()?.height?.toString() )
    // }


    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when(call?.method){
            "checkAndRequestPermission" -> {
                checkAndRequestPermission(result)
            }
            "flipCamera" -> {
                flipCamera()
            }
            "toggleFlash" -> {
                toggleFlash()
            }
            "pauseCamera" -> {
                pauseCamera()
            }
            "resumeCamera" -> {
                resumeCamera()
            }
        }
    }

    private fun checkAndRequestPermission(result: MethodChannel.Result?) {
        if (cameraPermissionContinuation != null) {
            result?.error("cameraPermission", "Camera permission request ongoing", null);
        }

        cameraPermissionContinuation = Runnable {
            cameraPermissionContinuation = null
            if (!hasCameraPermission()) {
                result?.error(
                        "cameraPermission", "MediaRecorderCamera permission not granted", null)
                return@Runnable
            }
        }

        requestingPermission = false
        if (hasCameraPermission()) {
            cameraPermissionContinuation?.run()
        } else {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                requestingPermission = true
                registrar
                        .activity()
                        .requestPermissions(
                                arrayOf(Manifest.permission.CAMERA),
                                CAMERA_REQUEST_ID)
            }
        }
    }

    fun bitmapToString(bitmap: Bitmap): String {
        val baos = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, baos)
        val b = baos.toByteArray()
        return Base64.encodeToString(b, Base64.URL_SAFE)
    }
}