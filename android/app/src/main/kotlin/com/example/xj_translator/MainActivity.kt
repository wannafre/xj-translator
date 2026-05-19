package com.example.xj_translator

import android.os.Bundle
import android.system.Os
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.xj_translator/native_lib"

    companion object {
        init {
            try {
                // Force global symbol resolution and run C++ static constructor registries
                System.loadLibrary("omp")
                System.loadLibrary("ggml-base")
                try {
                    System.loadLibrary("ggml-cpu")
                } catch (e: UnsatisfiedLinkError) {
                    // Expected on ARM64, where llama.cpp dynamic dispatch loads ARM-specific libs
                }
                System.loadLibrary("ggml")
                System.loadLibrary("llama")
            } catch (e: Throwable) {
                e.printStackTrace()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        try {
            val nativeLibraryDir = applicationInfo.nativeLibraryDir
            // Set both the backend path and backend directory environment variables
            Os.setenv("GGML_BACKEND_DIR", nativeLibraryDir, true)
            Os.setenv("GGML_BACKEND_PATH", "$nativeLibraryDir/libggml-cpu.so", true)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getNativeLibraryDir") {
                result.success(applicationInfo.nativeLibraryDir)
            } else {
                result.notImplemented()
            }
        }
    }
}
