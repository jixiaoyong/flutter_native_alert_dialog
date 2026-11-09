package io.github.jixiaoyong.native_alert_dialog

import android.app.Activity
import android.app.AlertDialog
import android.app.Application
import android.content.Context
import android.graphics.Color
import android.os.Handler
import android.os.Looper
import android.util.DisplayMetrics
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import android.widget.Toast
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

import io.github.jixiaoyong.native_alert_dialog.R
import java.lang.ref.WeakReference
import androidx.core.view.isVisible
import android.widget.LinearLayout

/** NativeAlertDialogPlugin */
class NativeAlertDialogPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private val mainHandler = Handler(Looper.getMainLooper())

    // Loading弹窗引用
    private var loadingDialog: AlertDialog? = null
    private var loadingActivityRef: WeakReference<Activity>? = null

    private var attached = false
    private val pendingResults = mutableSetOf<OnceResult>()
    private val dialogs = mutableMapOf<AlertDialog, Pair<Activity, Result>>()

    private class OnceResult(private val delegate: Result, private val onComplete: (OnceResult) -> Unit) : Result {
        private var completed = false
        private fun complete(action: () -> Unit) {
            if (completed) return
            completed = true
            onComplete(this)
            action()
        }

        override fun success(result: Any?) = complete { delegate.success(result) }
        override fun error(code: String, message: String?, details: Any?) =
            complete { delegate.error(code, message, details) }

        override fun notImplemented() = complete { delegate.notImplemented() }
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(
            flutterPluginBinding.binaryMessenger,
            "io.github.jixiaoyong.native_alert_dialog"
        )
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
        attached = true
        ActivityHolder.attach(context.applicationContext as Application, this) { activity ->
            dismissDialogs(activity)
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        val error = validateArguments(call)
        if (error != null) {
            result.error("INVALID_ARGUMENT", error, null)
            return
        }
        val once = OnceResult(result) { pendingResults.remove(it) }
        pendingResults.add(once)
        if (call.method == "getPlatformVersion") {
            once.success("Android " + android.os.Build.VERSION.RELEASE)
            return
        }
        mainHandler.post {
            if (!attached) {
                once.error("ENGINE_DETACHED", "Flutter engine is detached", null)
                return@post
            }
            try {
                handleMethodCall(call, once)
            } catch (e: Exception) {
                once.error("NATIVE_ERROR", e.message, null)
            }
        }
    }

    internal fun validateArguments(call: MethodCall): String? {
        val fields = when (call.method) {
            "showDialog" -> mapOf(
                "title" to String::class.java, "cancelText" to String::class.java,
                "confirmText" to String::class.java, "desText" to String::class.java,
                "desTextAlign" to String::class.java, "isDismissOnTouchOutside" to Boolean::class.javaObjectType
            )

            "showToast" -> mapOf("message" to String::class.java, "duration" to Int::class.javaObjectType)
            "openUrl" -> mapOf("url" to String::class.java, "title" to String::class.java)
            "showLoading" -> mapOf(
                "message" to String::class.java,
                "dismissOnTouchOutside" to Boolean::class.javaObjectType
            )

            else -> return null
        }
        val args = call.arguments ?: emptyMap<String, Any?>()
        if (args !is Map<*, *>) return "Arguments must be a map"
        for ((key, type) in fields) {
            val value = args[key]
            if (value != null && !type.isInstance(value)) return "$key has an invalid type"
        }
        if (call.method == "showDialog") {
            val themeColor = args["themeColor"]
            if (themeColor != null &&
                ((themeColor !is Int && themeColor !is Long) ||
                    (themeColor as Number).toLong() !in 0L..0xffffffffL)) {
                return "themeColor must be an integer between 0 and 0xffffffff"
            }
            val spans = args["desSpans"]
            if (spans != null) {
                if (spans !is List<*>) return "desSpans must be a list"
                for (span in spans) {
                    if (span !is Map<*, *>) return "Each desSpans item must be a map"
                    if (span["text"] != null && span["text"] !is String) return "Span text must be a string"
                    if (span["clickable"] != null && span["clickable"] !is Boolean) return "Span clickable must be a boolean"
                    if (span["clickKey"] != null && span["clickKey"] !is String) return "Span clickKey must be a string"
                }
            }
        }
        if (call.method == "openUrl" && !WebViewActivity.isSupportedUrl(args["url"] as? String)) {
            return "url must be an absolute HTTP or HTTPS URL with a host"
        }
        return null
    }

    private fun handleMethodCall(call: MethodCall, result: Result) {
        if (call.method in listOf("showDialog", "showLoading", "openUrl") && ActivityHolder.currentActivity == null) {
            result.error("NO_ACTIVITY", "No active Activity available", null)
            return
        }
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android " + android.os.Build.VERSION.RELEASE)
            }

            "showDialog" -> {
                val title = call.argument<String>("title") ?: ""
                val cancelText = call.argument<String>("cancelText")
                val confirmText = call.argument<String>("confirmText") ?: "确定"
                val desText = call.argument<String>("desText")
                val desSpans = call.argument<List<Map<String, Any>>>("desSpans")
                val desTextAlign = call.argument<String>("desTextAlign")
                val themeColor = call.argument<Number>("themeColor")?.toLong()?.toInt()
                    ?: 0xFF007AFF.toInt()
                val isDismissOnTouchOutside =
                    call.argument<Boolean>("isDismissOnTouchOutside") ?: false

                run {
                    showNativeDialog(
                        title,
                        desText,
                        desSpans,
                        cancelText,
                        confirmText,
                        desTextAlign,
                        themeColor,
                        isDismissOnTouchOutside,
                        result
                    )
                }
            }

            "showToast" -> {
                val message = call.argument<String>("message") ?: ""
                val duration = call.argument<Int>("duration") ?: 2000

                run {
                    showToast(message, duration)
                    result.success(null)
                }
            }

            "openUrl" -> {
                val url = call.argument<String>("url") ?: ""
                val title = call.argument<String>("title")
                run {
                    openUrl(url, title)
                    result.success(null)
                }
            }

            "showLoading" -> {
                val message = call.argument<String>("message")
                val dismissOnTouchOutside = call.argument<Boolean>("dismissOnTouchOutside") ?: false
                run {
                    showLoading(message, dismissOnTouchOutside)
                    result.success(null)
                }
            }

            "hideLoading" -> {
                run {
                    hideLoading()
                    result.success(null)
                }
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    private fun showNativeDialog(
        title: String,
        desText: String?,
        desSpans: List<Map<String, Any>>?,
        cancelText: String?,
        confirmText: String,
        desTextAlign: String?,
        themeColor: Int,
        isDismissOnTouchOutside: Boolean,
        result: Result
    ) {
        val topActivity = ActivityHolder.currentActivity
        if (topActivity == null) {
            result.error("NO_ACTIVITY", "No active Activity available", null)
            return
        }
        run {
            // 创建自定义对话框布局
            val inflater = LayoutInflater.from(topActivity)
            val dialogView = inflater.inflate(R.layout.custom_dialog, null)

            // 设置描述文本（支持富文本和点击）
            val descriptionTextView = dialogView.findViewById<TextView>(R.id.dialog_description)
            if (!desText.isNullOrEmpty()) {
                descriptionTextView.visibility = View.VISIBLE
                descriptionTextView.text = desText
                descriptionTextView.setTextColor(0xFF999999.toInt())
            } else if (!desSpans.isNullOrEmpty()) {
                descriptionTextView.visibility = View.VISIBLE
                val builder = android.text.SpannableStringBuilder()
                for (span in desSpans) {
                    val text = span["text"] as? String ?: ""
                    val clickable = span["clickable"] as? Boolean ?: false
                    val clickKey = span["clickKey"] as? String
                    val start = builder.length
                    builder.append(text)
                    val color = if (clickable) themeColor else android.graphics.Color.rgb(153, 153, 153)
                    builder.setSpan(
                        android.text.style.ForegroundColorSpan(color),
                        start,
                        builder.length,
                        android.text.Spannable.SPAN_EXCLUSIVE_EXCLUSIVE
                    )
                    if (clickable && clickKey != null) {
                        builder.setSpan(object : android.text.style.ClickableSpan() {
                            override fun onClick(widget: View) {
                                channel.invokeMethod("onDesSpanTap", mapOf("key" to clickKey))
                            }

                            override fun updateDrawState(ds: android.text.TextPaint) {
                                super.updateDrawState(ds)
                                ds.isUnderlineText = false
                                ds.color = color
                            }
                        }, start, builder.length, android.text.Spannable.SPAN_EXCLUSIVE_EXCLUSIVE)
                    }
                }
                descriptionTextView.text = builder
                descriptionTextView.movementMethod =
                    android.text.method.LinkMovementMethod.getInstance()
                descriptionTextView.highlightColor = android.graphics.Color.TRANSPARENT

            } else {
                descriptionTextView.visibility = View.GONE
            }

            if (descriptionTextView.isVisible) {
                descriptionTextView.gravity = when (desTextAlign) {
                    "left" -> Gravity.START or Gravity.CENTER_VERTICAL
                    "right" -> Gravity.END or Gravity.CENTER_VERTICAL
                    "center" -> Gravity.CENTER
                    "justify" -> Gravity.START or Gravity.CENTER_VERTICAL
                    "start" -> Gravity.START or Gravity.CENTER_VERTICAL
                    "end" -> Gravity.END or Gravity.CENTER_VERTICAL
                    else -> Gravity.CENTER
                }
            }

            // 获取屏幕宽度并计算适配比例
            val displayMetrics = DisplayMetrics()
            topActivity.windowManager?.defaultDisplay?.getMetrics(displayMetrics)
            val screenWidth = displayMetrics.widthPixels
            val scale = screenWidth / 375.0f

            // 设置标题文本
            val titleTextView = dialogView.findViewById<TextView>(R.id.dialog_title)
            titleTextView.text = title
            titleTextView.textSize = 17f

            var dialog: AlertDialog? = null

            // 设置取消按钮
            val cancelButton = dialogView.findViewById<TextView>(R.id.cancel_button)
            if (cancelText != null) {
                cancelButton.text = cancelText
                cancelButton.textSize = 16f
                cancelButton.setOnClickListener {
                    result.success(false)
                    dialog?.dismiss()
                }

            }
            val cancelButtonVisibility = if (cancelText != null) View.VISIBLE else View.GONE
            cancelButton.visibility = cancelButtonVisibility
            dialogView.findViewById<View>(R.id.space).visibility = cancelButtonVisibility

            // 设置确认按钮
            val confirmButton = dialogView.findViewById<TextView>(R.id.confirm_button)
            confirmButton.text = confirmText
            confirmButton.textSize = 16f
            confirmButton.background = confirmButton.background.mutate().apply { setTint(themeColor) }
            confirmButton.setOnClickListener {
                result.success(true)
                dialog?.dismiss()
            }

            // 当没有取消按钮时，调整确认按钮的布局
            if (cancelText == null) {
                val buttonContainer = dialogView.findViewById<LinearLayout>(R.id.button_container)
                val layoutParams = confirmButton.layoutParams as LinearLayout.LayoutParams

                // 在视图测量完成后设置宽度
                buttonContainer.post {
                    val newLayoutParams = confirmButton.layoutParams as LinearLayout.LayoutParams
                    newLayoutParams.width = (buttonContainer.width * 0.6).toInt()
                    layoutParams.weight = 0f
                    confirmButton.layoutParams = newLayoutParams
                }
            }

            // 创建对话框
            val builder = AlertDialog.Builder(topActivity, R.style.TransparentDialogTheme)
            builder.setView(dialogView)

            // 设置对话框不可取消
            builder.setCancelable(isDismissOnTouchOutside)

            val shownDialog = builder.create()
            dialog = shownDialog
            shownDialog.setCanceledOnTouchOutside(isDismissOnTouchOutside)
            shownDialog.setOnDismissListener {
                dialogs.remove(shownDialog)
                result.success(false)
            }
            dialogs[shownDialog] = topActivity to result
            try {
                shownDialog.show()
            } catch (e: Exception) {
                result.error("SHOW_FAILED", e.message, null)
                dialogs.remove(shownDialog)
                shownDialog.dismiss()
                return
            }

            // 设置对话框宽度为屏幕宽度减去两侧边距
            val window = shownDialog.window
            if (window != null) {
                val params = window.attributes
                // 根据Flutter设计，水平边距为36*2=72，所以宽度为屏幕宽度减去72
                params.width = (screenWidth - (72 * scale)).toInt()
                window.attributes = params

                // 设置背景透明，使用自定义布局的背景
                window.setBackgroundDrawableResource(android.R.color.transparent)

                // 移除对话框默认的内边距，防止圆角被裁剪
                window.decorView.setPadding(0, 0, 0, 0)
            }
        }
    }

    private fun showToast(message: String, duration: Int) {
        val topActivity = ActivityHolder.currentActivity
        val ctx = topActivity ?: context

        // 创建自定义 Toast
        val toast = Toast(ctx)
        val inflater = LayoutInflater.from(ctx)
        val layout = inflater.inflate(R.layout.toast_layout, null)

        // 设置文本
        val textView = layout.findViewById<TextView>(R.id.toast_text)
        textView.text = message

        // 获取屏幕尺寸
        val displayMetrics = ctx.resources.displayMetrics
        val screenWidth = displayMetrics.widthPixels
        val scale = screenWidth / 375f

        // 设置 Toast 属性
        // 参考iOS的距离，距离底部80*scale
        val bottomMargin = (80 * scale).toInt()
        toast.setGravity(Gravity.BOTTOM or Gravity.CENTER_HORIZONTAL, 0, bottomMargin)
        toast.duration = if (duration > 2000) Toast.LENGTH_LONG else Toast.LENGTH_SHORT
        toast.view = layout

        toast.show()
    }

    private fun openUrl(url: String, title: String?) {
        val topActivity = ActivityHolder.currentActivity ?: error("No active Activity available")
        val intent = android.content.Intent(topActivity, WebViewActivity::class.java)
        intent.putExtra(WebViewActivity.EXTRA_URL, url)
        intent.putExtra(WebViewActivity.EXTRA_TITLE, title)
        topActivity.startActivity(intent)
    }

    private fun showLoading(message: String?, dismissOnTouchOutside: Boolean) {
        val topActivity = ActivityHolder.currentActivity
        if (topActivity != null && !topActivity.isFinishing && !topActivity.isDestroyed) {
            try {
                // 如果之前的 dialog 还在显示，先关闭它
                if (loadingDialog?.isShowing == true) {
                    loadingDialog?.dismiss()
                }
                loadingDialog = null

                val builder = AlertDialog.Builder(topActivity, R.style.TransparentDialogTheme)
                val inflater = LayoutInflater.from(topActivity)
                val view = inflater.inflate(R.layout.loading_dialog, null)
                val textView = view.findViewById<TextView>(R.id.loading_text)
                if (!message.isNullOrEmpty()) {
                    textView.text = message
                    textView.visibility = View.VISIBLE
                    textView.maxWidth = (120 * topActivity.resources.displayMetrics.density).toInt()
                } else {
                    textView.visibility = View.GONE
                }
                builder.setView(view)
                builder.setCancelable(dismissOnTouchOutside)
                loadingDialog = builder.create()
                val shownDialog = loadingDialog!!
                shownDialog.setCanceledOnTouchOutside(dismissOnTouchOutside)
                shownDialog.setOnDismissListener {
                    if (loadingDialog === shownDialog) cleanupLoadingDialog()
                }
                loadingActivityRef = WeakReference(topActivity)
                loadingDialog?.show()
                loadingDialog?.window?.decorView?.setPadding(0, 0, 0, 0)
                loadingDialog?.window?.setBackgroundDrawableResource(android.R.color.transparent)

                val size = (120 * topActivity.resources.displayMetrics.density).toInt()
                loadingDialog?.window?.setLayout(size, ViewGroup.LayoutParams.WRAP_CONTENT)
            } catch (e: Exception) {
                e.printStackTrace()
                hideLoading()
                throw e
            }
        }
    }

    private fun hideLoading() {
        try {
            if (loadingDialog?.isShowing == true) {
                loadingDialog?.dismiss()
            }
        } catch (e: Exception) {
            e.printStackTrace()
        } finally {
            cleanupLoadingDialog()
        }
    }

    private fun cleanupLoadingDialog() {
        loadingDialog = null
        loadingActivityRef = null
    }

    private fun dismissDialogs(activity: Activity? = null) {
        dialogs.toMap().forEach { (dialog, owner) ->
            if (activity == null || owner.first === activity) {
                dialogs.remove(dialog)
                owner.second.success(false)
                try {
                    dialog.dismiss()
                } catch (_: Exception) {
                }
            }
        }
        if (activity == null || loadingActivityRef?.get() === activity) hideLoading()
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        attached = false
        channel.setMethodCallHandler(null)
        mainHandler.removeCallbacksAndMessages(null)
        pendingResults.toList().forEach { it.error("ENGINE_DETACHED", "Flutter engine is detached", null) }
        dismissDialogs()
        ActivityHolder.detach(this)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        ActivityHolder.seed(binding.activity)
    }

    override fun onDetachedFromActivityForConfigChanges() {
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        ActivityHolder.seed(binding.activity)
    }

    override fun onDetachedFromActivity() {
        // The application callback still tracks any native Activity covering Flutter.
    }
}
