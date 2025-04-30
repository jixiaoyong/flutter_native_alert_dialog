package io.github.jixiaoyong.native_alert_dialog

import android.os.Bundle
import android.webkit.WebView
import android.webkit.WebViewClient
import android.graphics.Color
import android.view.WindowManager
import android.view.View
import androidx.appcompat.app.AppCompatActivity

class WebViewActivity : AppCompatActivity() {
    companion object {
        const val EXTRA_URL = "url"
        const val EXTRA_TITLE = "title"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // 设置状态栏样式
        window.addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS)
        window.statusBarColor = Color.WHITE
        window.decorView.systemUiVisibility = android.view.View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR
        
        setContentView(R.layout.activity_web_view)
        
        // 设置标题栏
        val title = intent.getStringExtra(EXTRA_TITLE)
        val titleBar = findViewById<View>(R.id.titleBar)
        val titleText = findViewById<android.widget.TextView>(R.id.titleText)
        
        if (title.isNullOrEmpty()) {
            titleText.visibility = View.GONE
        } else {
            titleText.text = title
            titleText.visibility = View.VISIBLE
        }
        
        // 设置返回按钮
        findViewById<android.widget.ImageButton>(R.id.backButton).setOnClickListener {
            finish()
        }
        
        // 配置 WebView
        val webView = findViewById<WebView>(R.id.webView)
        val settings = webView.settings
        settings.javaScriptEnabled = true
        settings.domStorageEnabled = true
        settings.useWideViewPort = true
        settings.loadWithOverviewMode = true
        
        // 设置 WebViewClient
        webView.webViewClient = WebViewClient()
        
        // 加载 URL
        val url = intent.getStringExtra(EXTRA_URL) ?: return
        webView.loadUrl(url)
    }
    
    override fun onBackPressed() {
        val webView = findViewById<WebView>(R.id.webView)
        if (webView.canGoBack()) {
            webView.goBack()
        } else {
            super.onBackPressed()
        }
    }
} 