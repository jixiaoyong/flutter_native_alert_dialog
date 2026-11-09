package io.github.jixiaoyong.native_alert_dialog

import android.app.Activity
import android.app.Application
import android.os.Looper
import android.widget.TextView
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.mockito.Mockito.*
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import org.robolectric.shadows.ShadowAlertDialog

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
class NativeAlertDialogPluginTest {
    private lateinit var plugin: NativeAlertDialogPlugin
    private lateinit var binding: FlutterPlugin.FlutterPluginBinding

    @Before fun setUp() {
        binding = mock(FlutterPlugin.FlutterPluginBinding::class.java)
        `when`(binding.applicationContext).thenReturn(RuntimeEnvironment.getApplication())
        `when`(binding.binaryMessenger).thenReturn(mock(BinaryMessenger::class.java))
        plugin = NativeAlertDialogPlugin()
        plugin.onAttachedToEngine(binding)
    }

    @After fun tearDown() { plugin.onDetachedFromEngine(binding) }

    private fun call(method: String, args: Any? = null): MethodChannel.Result {
        val result = mock(MethodChannel.Result::class.java)
        plugin.onMethodCall(MethodCall(method, args), result)
        shadowOf(Looper.getMainLooper()).idle()
        return result
    }

    private fun resumeActivity(): Activity = Robolectric.buildActivity(Activity::class.java).setup().get().also {
        ActivityHolder.onActivityResumed(it)
    }

    @Test fun noActivityCompletesAllActivityDependentCalls() {
        for (method in listOf("showDialog", "showLoading", "openUrl")) {
            val result = call(method, if (method == "openUrl") mapOf("url" to "https://example.com") else null)
            verify(result).error(eq("NO_ACTIVITY"), anyString(), isNull())
            verifyNoMoreInteractions(result)
        }
    }

    @Test fun validatesNestedSpansBeforeCasting() {
        for (spans in listOf("bad", listOf("bad"), listOf(mapOf("clickable" to "true")), listOf(mapOf("text" to 1)))) {
            val result = call("showDialog", mapOf("desSpans" to spans))
            verify(result).error(eq("INVALID_ARGUMENT"), anyString(), isNull())
            verifyNoMoreInteractions(result)
        }
        assertNull(plugin.validateArguments(MethodCall("showDialog", mapOf("cancelText" to null, "desTextAlign" to "start"))))
    }

    private fun assertDialogTheme(args: Map<String, Any?>, expectedColor: Int) {
        resumeActivity()
        call("showDialog", args + mapOf(
            "cancelText" to "取消",
            "desSpans" to listOf(
                mapOf("text" to "正文"),
                mapOf("text" to "链接", "clickable" to true, "clickKey" to "link")
            )
        ))
        val dialog = ShadowAlertDialog.getLatestAlertDialog()
        val confirm = dialog.findViewById<TextView>(R.id.confirm_button)
        val background = confirm.background as android.graphics.drawable.GradientDrawable
        assertEquals(16f * confirm.resources.displayMetrics.density, background.cornerRadius, 0.01f)
        val tint = org.robolectric.util.ReflectionHelpers.getField<android.content.res.ColorStateList>(
            background.constantState, "mTint"
        )
        assertEquals(expectedColor, tint.defaultColor)
        assertEquals(0xFFAAAAAA.toInt(), dialog.findViewById<TextView>(R.id.cancel_button).currentTextColor)
        val description = dialog.findViewById<TextView>(R.id.dialog_description)
        val spans = description.text as android.text.Spanned
        val colors = spans.getSpans(0, spans.length, android.text.style.ForegroundColorSpan::class.java)
        assertEquals(0xFF999999.toInt(), colors[0].foregroundColor)
        assertEquals(expectedColor, colors[1].foregroundColor)
        val clickable = spans.getSpans(0, spans.length, android.text.style.ClickableSpan::class.java).single()
        val paint = android.text.TextPaint().apply { isUnderlineText = true }
        clickable.updateDrawState(paint)
        assertEquals(expectedColor, paint.color)
        assertFalse(paint.isUnderlineText)
    }

    @Test fun customThemeColorAcceptsUnsignedLongAndPreservesOtherStyles() {
        assertDialogTheme(mapOf("themeColor" to 0xFF123456L), 0xFF123456.toInt())
    }

    @Test fun absentThemeColorUsesDefaultBlue() {
        assertDialogTheme(emptyMap(), 0xFF007AFF.toInt())
    }

    @Test fun themeColorAcceptsOnlyUnsigned32BitIntOrLong() {
        for (color in listOf(0, Int.MAX_VALUE, 0L, 0xffffffffL)) {
            assertNull(plugin.validateArguments(MethodCall("showDialog", mapOf("themeColor" to color))))
        }
        for (color in listOf(-1, -1L, 0x100000000L, Long.MAX_VALUE, 1.0f, 1.0, "4278190335", true, 1.toShort())) {
            val result = call("showDialog", mapOf("themeColor" to color))
            verify(result).error(eq("INVALID_ARGUMENT"), anyString(), isNull())
            verifyNoMoreInteractions(result)
        }
    }

    @Test fun multipleDialogsKeepIndependentOnceOnlyResults() {
        resumeActivity()
        val first = call("showDialog", mapOf("cancelText" to null, "desTextAlign" to "right"))
        val firstDialog = ShadowAlertDialog.getLatestAlertDialog()
        assertEquals(android.view.View.GONE, firstDialog.findViewById<TextView>(R.id.cancel_button).visibility)
        val second = call("showDialog", null)
        val secondDialog = ShadowAlertDialog.getLatestAlertDialog()
        firstDialog.findViewById<TextView>(R.id.confirm_button).performClick()
        firstDialog.dismiss()
        secondDialog.dismiss()
        shadowOf(Looper.getMainLooper()).idle()
        verify(first).success(true)
        verify(second).success(false)
        verifyNoMoreInteractions(first, second)
    }

    @Test fun nativeActivityOverridesFlutterHostAndDestroySettlesResult() {
        val flutterHost = resumeActivity()
        val activityBinding = mock(ActivityPluginBinding::class.java)
        `when`(activityBinding.activity).thenReturn(flutterHost)
        plugin.onAttachedToActivity(activityBinding)
        val nativeHost = resumeActivity()
        plugin.onDetachedFromActivity()
        assertSame(nativeHost, ActivityHolder.currentActivity)
        val result = call("showDialog", mapOf("isDismissOnTouchOutside" to true))
        val dialog = ShadowAlertDialog.getLatestAlertDialog()
        dialog.cancel()
        ActivityHolder.onActivityDestroyed(nativeHost)
        shadowOf(Looper.getMainLooper()).idle()
        verify(result).success(false)
        verifyNoMoreInteractions(result)
    }

    @Test fun destroyedActivitySettlesOutstandingDialogAndLoading() {
        val activity = resumeActivity()
        val result = call("showDialog", mapOf("desText" to "description", "desTextAlign" to "right"))
        val dialog = ShadowAlertDialog.getLatestAlertDialog()
        assertEquals(android.view.Gravity.END or android.view.Gravity.CENTER_VERTICAL,
            dialog.findViewById<TextView>(R.id.dialog_description).gravity)
        call("showLoading")
        val loading = ShadowAlertDialog.getLatestAlertDialog()
        ActivityHolder.onActivityDestroyed(activity)
        shadowOf(Looper.getMainLooper()).idle()
        assertFalse(dialog.isShowing)
        assertFalse(loading.isShowing)
        verify(result).success(false)
        verifyNoMoreInteractions(result)
    }

    @Test fun platformVersionAndUnknownMethodRemainSupported() {
        verify(call("getPlatformVersion")).success("Android " + android.os.Build.VERSION.RELEASE)
        verify(call("unknown")).notImplemented()
    }

    @Test fun loadingCanRepeatAndIsDismissedWhenEngineDetaches() {
        resumeActivity()
        val first = call("showLoading")
        val old = ShadowAlertDialog.getLatestAlertDialog()
        val second = call("showLoading", mapOf("dismissOnTouchOutside" to true))
        val latest = ShadowAlertDialog.getLatestAlertDialog()
        assertFalse(old.isShowing)
        assertTrue(latest.isShowing)
        plugin.onDetachedFromEngine(binding)
        assertFalse(latest.isShowing)
        assertNull(ActivityHolder.currentActivity)
        verify(first).success(null)
        verify(second).success(null)
    }

    @Test fun detachCompletesQueuedAndDisplayedCallsOnlyOnce() {
        resumeActivity()
        val displayed = call("showDialog")
        val queued = mock(MethodChannel.Result::class.java)
        plugin.onMethodCall(MethodCall("showLoading", null), queued)
        plugin.onDetachedFromEngine(binding)
        shadowOf(Looper.getMainLooper()).idle()
        verify(displayed).error(eq("ENGINE_DETACHED"), anyString(), isNull())
        verify(queued).error(eq("ENGINE_DETACHED"), anyString(), isNull())
        verifyNoMoreInteractions(displayed, queued)
    }

    @Test fun holderIsSharedUntilLastEngineDetaches() {
        val owner = Any()
        ActivityHolder.attach(RuntimeEnvironment.getApplication(), owner) {}
        val activity = resumeActivity()
        plugin.onDetachedFromEngine(binding)
        assertSame(activity, ActivityHolder.currentActivity)
        ActivityHolder.detach(owner)
        assertNull(ActivityHolder.currentActivity)
    }

    @Test fun urlBoundaryAllowsHttpAndHttpsButRejectsLocalAndScriptUrls() {
        for (url in listOf("http://example.com/path?q=1", "https://example.com/#hash", "HTTPS://example.com")) {
            assertTrue(url, WebViewActivity.isSupportedUrl(url))
        }
        for (url in listOf("", "https:///", "file:///etc/hosts", "javascript:alert(1)", "data:text/html,test", "intent://test", "https://example.com/ bad")) {
            assertFalse(url, WebViewActivity.isSupportedUrl(url))
        }
    }
}
