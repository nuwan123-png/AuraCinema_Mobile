package com.auracinema.app

import android.os.Bundle
import android.webkit.CookieManager
import android.webkit.WebView
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        CookieManager.getInstance().setAcceptCookie(true)
        WebView.enableSlowWholeDocumentDraw()
    }
}
