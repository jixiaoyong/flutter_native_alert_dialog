package io.jixiaoyong.native_alert_dialog

import android.app.Activity
import android.app.AlertDialog
import android.content.Context
import android.graphics.Color
import android.os.Handler
import android.os.Looper
import android.util.DisplayMetrics
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.widget.TextView
import android.widget.Toast
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** NativeAlertDialogPlugin */
class NativeAlertDialogPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var activity: Activity? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "native_alert_dialog")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }

            "showDialog" -> {
                val title = call.argument<String>("title") ?: ""
                val cancelText = call.argument<String>("cancelText") ?: "取消"
                val confirmText = call.argument<String>("confirmText") ?: "确定"
                val desText = call.argument<String>("desText")
                val desSpans = call.argument<List<Map<String, Any>>>("desSpans")

                if (activity == null) {
                    result.error("NO_ACTIVITY", "Activity is not available", null)
                    return
                }

                mainHandler.post {
                    showNativeDialog(title, desText, desSpans, cancelText, confirmText, result)
                }
            }

            "showToast" -> {
                val message = call.argument<String>("message") ?: ""
                val duration = call.argument<Int>("duration") ?: 2000

                mainHandler.post {
                    showToast(message, duration)
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
        cancelText: String,
        confirmText: String,
        result: Result
    ) {
        // 创建自定义对话框布局
        val inflater = LayoutInflater.from(activity)
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
                val color = if (clickable) android.graphics.Color.rgb(26, 26, 26) else android.graphics.Color.rgb(153, 153, 153)
                builder.setSpan(android.text.style.ForegroundColorSpan(color), start, builder.length, android.text.Spannable.SPAN_EXCLUSIVE_EXCLUSIVE)
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
            descriptionTextView.movementMethod = android.text.method.LinkMovementMethod.getInstance()
            descriptionTextView.highlightColor = android.graphics.Color.TRANSPARENT
            descriptionTextView.gravity = Gravity.CENTER
        } else {
            descriptionTextView.visibility = View.GONE
        }

        // 获取屏幕宽度并计算适配比例
        val displayMetrics = DisplayMetrics()
        activity?.windowManager?.defaultDisplay?.getMetrics(displayMetrics)
        val screenWidth = displayMetrics.widthPixels
        val scale = screenWidth / 375.0f

        // 设置标题文本
        val titleTextView = dialogView.findViewById<TextView>(R.id.dialog_title)
        titleTextView.text = title
        titleTextView.textSize = 17f

        var dialog: AlertDialog? = null

        // 设置取消按钮
        val cancelButton = dialogView.findViewById<TextView>(R.id.cancel_button)
        cancelButton.text = cancelText
        cancelButton.textSize = 16f
        cancelButton.setOnClickListener {
            dialog?.dismiss()
            result.success(false)
        }

        // 设置确认按钮
        val confirmButton = dialogView.findViewById<TextView>(R.id.confirm_button)
        confirmButton.text = confirmText
        confirmButton.textSize = 16f
        confirmButton.setOnClickListener {
            dialog?.dismiss()
            result.success(true)
        }

        // 创建对话框
        val builder = AlertDialog.Builder(activity, R.style.TransparentDialogTheme)
        builder.setView(dialogView)

        // 设置对话框不可取消
        builder.setCancelable(false)

        dialog = builder.create()
        dialog.show()

        // 设置对话框宽度为屏幕宽度减去两侧边距
        val window = dialog.window
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

    private fun showToast(message: String, duration: Int) {
        val toast = Toast.makeText(
            context,
            message,
            if (duration > 2000) Toast.LENGTH_LONG else Toast.LENGTH_SHORT
        )
        toast.setGravity(Gravity.CENTER, 0, 0)
        toast.show()
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }
}
