package io.github.jixiaoyong.native_alert_dialog

import android.os.Bundle
import android.webkit.WebView
import android.webkit.WebViewClient
import android.webkit.WebResourceRequest
import android.graphics.Color
import android.view.WindowManager
import android.view.View
import androidx.appcompat.app.AppCompatActivity
import android.webkit.WebSettings
import android.view.MotionEvent

class WebViewActivity : AppCompatActivity() {
    companion object {
        const val EXTRA_URL = "url"
        const val EXTRA_TITLE = "title"

        internal fun isSupportedUrl(url: String?): Boolean {
            if (url.isNullOrBlank()) return false
            return try {
                val uri = android.net.Uri.parse(url)
                (uri.scheme.equals("http", true) || uri.scheme.equals("https", true)) &&
                    !uri.host.isNullOrBlank() && url.none { it.isWhitespace() || it.isISOControl() }
            } catch (_: Exception) { false }
        }
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

        // 基本设置
        settings.javaScriptEnabled = true
        settings.domStorageEnabled = true

        // 移动设备适配设置
        settings.useWideViewPort = true
        settings.loadWithOverviewMode = true
        settings.setSupportZoom(false)
        settings.builtInZoomControls = false
        settings.displayZoomControls = false

        // 设置默认字体大小
        settings.defaultFontSize = 16

        // 设置缓存模式
        settings.cacheMode = WebSettings.LOAD_DEFAULT

        // 设置 User-Agent
        val userAgent = settings.userAgentString
        settings.userAgentString = userAgent.replace("Linux; ", "Linux; Android ")

        // 设置 WebViewClient
        webView.webViewClient = object : WebViewClient() {
            override fun shouldOverrideUrlLoading(view: WebView?, request: WebResourceRequest?): Boolean =
                !isSupportedUrl(request?.url?.toString())

            @Deprecated("Legacy WebView callback")
            override fun shouldOverrideUrlLoading(view: WebView?, url: String?): Boolean =
                !isSupportedUrl(url)

            override fun onPageFinished(view: WebView?, url: String?) {
                super.onPageFinished(view, url)
                // 注入 viewport meta 标签
                view?.evaluateJavascript("""
                    (function() {
                        var meta = document.createElement('meta');
                        meta.setAttribute('name', 'viewport');
                        meta.setAttribute('content', 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no');
                        document.getElementsByTagName('head')[0].appendChild(meta);
                    })();
                """.trimIndent(), null)
            }
        }

        // 启用手势导航
        webView.setOnTouchListener { _, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    webView.parent.requestDisallowInterceptTouchEvent(true)
                }
                MotionEvent.ACTION_UP -> {
                    webView.parent.requestDisallowInterceptTouchEvent(false)
                }
            }
            false
        }

        // 加载 URL
        val url = intent.getStringExtra(EXTRA_URL)
        if (!isSupportedUrl(url)) {
            finish()
            return
        }
        webView.loadUrl(url!!)
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