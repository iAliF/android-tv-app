package com.mawaqit.androidtv

import io.flutter.embedding.android.FlutterActivity
import android.content.pm.PackageManager
import androidx.annotation.NonNull
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor.DartEntrypoint
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import java.io.IOException
import android.app.Activity
import android.content.Intent

class MainActivity : FlutterActivity() {
    private val CHANNEL = "nativeMethodsChannel"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "isPackageInstalled") {
                val packageName = call.argument<String>("packageName")
                val isInstalled = isPackageInstalled(packageName)
                result.success(isInstalled)
            } else  if (call.method == "clearAppData") {
             
                val isSuccess = clearDataRestart()
                result.success(isSuccess)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun isPackageInstalled(packageName: String?): Boolean {
        val packageManager = applicationContext.packageManager
        return try {
            packageManager.getPackageInfo(packageName!!, PackageManager.GET_ACTIVITIES)
            true
        } catch (e: PackageManager.NameNotFoundException) {
            false
        }
    }
private fun clearDataRestart(): Boolean {
    try {
        val processBuilder = ProcessBuilder()
        processBuilder.command("sh", "-c", """
            pm clear com.mawaqit.androidtv
        """.trimIndent())
        val process = processBuilder.start()
        val exitCode = process.waitFor()
        if (exitCode == 0) {
            triggerRestart(this)
            return true
        }
        return false
    } catch (e: IOException) {
        e.printStackTrace()
        return false
    } catch (e: InterruptedException) {
        e.printStackTrace()
        return false
    }
}

private fun triggerRestart(context: Activity) {
    val intent = Intent(context, MainActivity::class.java)
    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
    context.startActivity(intent)
    if (context is Activity) {
        (context as Activity).finish()
    }
    Runtime.getRuntime().exit(0)
}
}
