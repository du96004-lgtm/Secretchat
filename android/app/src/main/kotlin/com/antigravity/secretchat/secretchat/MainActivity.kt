package com.antigravity.secretchat.secretchat

import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle
import android.view.WindowManager

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // 🔒 Prevent screenshots and screen recording at OS level
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )
    }
}
