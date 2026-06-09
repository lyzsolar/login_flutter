package com.lyzsolar.login_flutter

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.view.WindowManager
import android.os.Bundle
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.content.Context
import android.os.Build

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.lyzsolar.login_flutter/security"
    private var isMockDetected = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Bloquea capturas de pantalla
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        startLocationUpdates()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "isFakeGPS") {
                result.success(isMockDetected)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun startLocationUpdates() {
        val locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
        try {
            val locationListener = object : LocationListener {
                override fun onLocationChanged(location: Location) {
                    isMockDetected = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        location.isMock
                    } else {
                        @Suppress("DEPRECATION")
                        location.isFromMockProvider
                    }
                }
                override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {}
                override fun onProviderEnabled(provider: String) {}
                override fun onProviderDisabled(provider: String) {}
            }

            locationManager.requestLocationUpdates(
                LocationManager.GPS_PROVIDER,
                1000L,
                1f,
                locationListener
            )

            // Verificación inmediata con la última ubicación conocida
            val lastLocation = locationManager.getLastKnownLocation(LocationManager.GPS_PROVIDER)
            if (lastLocation != null) {
                isMockDetected = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    lastLocation.isMock
                } else {
                    @Suppress("DEPRECATION")
                    lastLocation.isFromMockProvider
                }
            }
        } catch (e: SecurityException) {
            isMockDetected = false
        }
    }
}
