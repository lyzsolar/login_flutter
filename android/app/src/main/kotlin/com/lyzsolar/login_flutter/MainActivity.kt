package com.lyzsolar.login_flutter

import io.flutter.embedding.android.FlutterActivity
import android.view.WindowManager
import android.os.Bundle

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceSt
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }
}