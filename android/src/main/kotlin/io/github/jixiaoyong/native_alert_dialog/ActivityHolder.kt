package io.github.jixiaoyong.native_alert_dialog

import android.app.Activity
import android.app.Application
import android.os.Bundle
import java.lang.ref.WeakReference

object ActivityHolder : Application.ActivityLifecycleCallbacks {
    private var _currentActivity: WeakReference<Activity>? = null
    val currentActivity: Activity?
        get() = _currentActivity?.get()

    override fun onActivityResumed(activity: Activity) {
        _currentActivity = WeakReference(activity)
    }
    override fun onActivityPaused(activity: Activity) {}
    override fun onActivityStarted(activity: Activity) {}
    override fun onActivityDestroyed(activity: Activity) {
        if (_currentActivity?.get() == activity) {
            _currentActivity = null
        }
    }
    override fun onActivitySaveInstanceState(activity: Activity, outState: Bundle) {}
    override fun onActivityStopped(activity: Activity) {}
    override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) {}
} 