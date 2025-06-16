package com.example.ai_scheduling_app

import android.app.Application
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugins.GeneratedPluginRegistrant

class FlutterApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        
        // Create and cache a FlutterEngine
        val flutterEngine = FlutterEngine(this)
        
        // Start executing Dart code in the FlutterEngine
        flutterEngine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint.createDefault()
        )
        
        // Register plugins
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        
        // Cache the pre-warmed FlutterEngine
        FlutterEngineCache
            .getInstance()
            .put("default_engine_id", flutterEngine)
    }
}