package com.maxafrica.gpbenin

import android.app.PictureInPictureParams
import android.content.res.Configuration
import android.os.Build
import android.util.Rational
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var pip: MethodChannel? = null

    override fun configureFlutterEngine(engine: FlutterEngine) {
        super.configureFlutterEngine(engine)
        pip = MethodChannel(engine.dartExecutor.binaryMessenger, "gp/pip")
        pip!!.setMethodCallHandler { call, result ->
            val ok = Build.VERSION.SDK_INT >= Build.VERSION_CODES.O
            when (call.method) {
                "available" -> result.success(ok)
                "enter" -> {
                    if (ok) enterPictureInPictureMode(
                        PictureInPictureParams.Builder().setAspectRatio(Rational(16, 9)).build()
                    )
                    result.success(ok)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onPictureInPictureModeChanged(isInPictureInPictureMode: Boolean, newConfig: Configuration) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        pip?.invokeMethod("pipChanged", isInPictureInPictureMode)
    }
}
