package io.github.jixiaoyong.native_alert_dialog

import android.app.Activity
import android.app.Application
import android.os.Bundle
import java.lang.ref.WeakReference

// Keep tracking native activities too: ActivityAware alone only sees the Flutter host.
object ActivityHolder : Application.ActivityLifecycleCallbacks {
    private var application: Application? = null
    private val owners = mutableMapOf<Any, (Activity) -> Unit>()
    private var current: WeakReference<Activity>? = null
    val currentActivity: Activity?
        get() = current?.get()?.takeUnless { it.isFinishing || it.isDestroyed }

    fun attach(application: Application, owner: Any, onDestroyed: (Activity) -> Unit) {
        if (owners.isEmpty()) {
            this.application = application
            application.registerActivityLifecycleCallbacks(this)
        }
        owners[owner] = onDestroyed
    }

    fun detach(owner: Any) {
        owners.remove(owner)
        if (owners.isEmpty()) {
            application?.unregisterActivityLifecycleCallbacks(this)
            application = null
            current = null
        }
    }

    fun seed(activity: Activity) {
        if (currentActivity == null) current = WeakReference(activity)
    }

    override fun onActivityResumed(activity: Activity) {
        current = WeakReference(activity)
    }
    override fun onActivityPaused(activity: Activity) {
        if (current?.get() === activity) current = null
    }
    override fun onActivityStarted(activity: Activity) {}
    override fun onActivityDestroyed(activity: Activity) {
        if (current?.get() === activity) current = null
        owners.values.toList().forEach { it(activity) }
    }
    override fun onActivitySaveInstanceState(activity: Activity, outState: Bundle) {}
    override fun onActivityStopped(activity: Activity) {}
    override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) {}
}
