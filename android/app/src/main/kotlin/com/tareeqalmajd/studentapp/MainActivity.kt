package com.tareeqalmajd.studentapp

import android.hardware.display.DisplayManager
import android.os.Build
import android.view.Display
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import java.util.function.Consumer

/**
 * Blocks screen recording while leaving screenshots working.
 *
 * Android has no flag that separates the two: FLAG_SECURE blocks recording,
 * screenshots, and the recents thumbnail all at once. So instead of setting it
 * permanently, this activity detects when a capture is actually in progress and
 * applies FLAG_SECURE only for that window of time. Screenshots taken normally
 * are unaffected; anything recorded comes out black.
 *
 * Detection depends on the OS version:
 *
 *  - Android 15 (API 35) and newer use WindowManager.addScreenRecordingCallback,
 *    which is an official signal about *this app's* windows being recorded. This
 *    is exact.
 *
 *  - Older versions have no public API for it. The fallback watches for the
 *    virtual display that MediaProjection creates when a recorder starts.
 *    Displays that report themselves in the PRESENTATION category are ignored so
 *    that ordinary external monitors, TVs, Android Auto and DeX do not trip it.
 *    This catches the common recorder apps but cannot be called airtight.
 *
 * If guaranteed blocking on pre-Android-15 devices matters more than screenshots
 * working there, change [legacyPolicy] to [LegacyPolicy.ALWAYS_SECURE]. That
 * makes older devices refuse recording unconditionally, at the cost of also
 * refusing screenshots on those devices.
 */
class MainActivity : FlutterActivity() {

    private enum class LegacyPolicy {
        /** Pre-API-35: heuristic detection. Screenshots keep working. */
        DETECT_ONLY,

        /** Pre-API-35: FLAG_SECURE always on. Blocks recording and screenshots. */
        ALWAYS_SECURE,
    }

    private val legacyPolicy = LegacyPolicy.DETECT_ONLY

    private var eventSink: EventChannel.EventSink? = null
    private var displayManager: DisplayManager? = null
    private var displayListener: DisplayManager.DisplayListener? = null
    private var recordingCallback: Consumer<Int>? = null
    private var isCaptured = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    events?.success(isCaptured)
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            },
        )
    }

    override fun onStart() {
        super.onStart()
        startGuard()
    }

    override fun onStop() {
        stopGuard()
        super.onStop()
    }

    private fun startGuard() {
        if (Build.VERSION.SDK_INT >= 35) {
            startModernGuard()
            return
        }

        if (legacyPolicy == LegacyPolicy.ALWAYS_SECURE) {
            applySecure(true)
            return
        }

        startLegacyGuard()
    }

    private fun stopGuard() {
        removeModernGuard()

        displayListener?.let { listener ->
            runCatching { displayManager?.unregisterDisplayListener(listener) }
        }
        displayListener = null
        displayManager = null
    }

    private fun startModernGuard() {
        val wm = runCatching { getSystemService(WindowManager::class.java) }.getOrNull()
        if (wm == null) {
            startLegacyGuard()
            return
        }

        val callback = Consumer<Int> { state ->
            onCaptureStateChanged(state == WindowManager.SCREEN_RECORDING_STATE_VISIBLE)
        }

        val initial = runCatching {
            wm.addScreenRecordingCallback(mainExecutor, callback)
        }.getOrNull()

        if (initial == null) {
            // Permission missing or a vendor ROM without the API. Fall back rather
            // than leaving the screen unprotected.
            startLegacyGuard()
            return
        }

        recordingCallback = callback
        onCaptureStateChanged(initial == WindowManager.SCREEN_RECORDING_STATE_VISIBLE)
    }

    private fun removeModernGuard() {
        val callback = recordingCallback ?: return
        recordingCallback = null

        if (Build.VERSION.SDK_INT < 35) return
        runCatching {
            getSystemService(WindowManager::class.java)?.removeScreenRecordingCallback(callback)
        }
    }

    private fun startLegacyGuard() {
        val manager = runCatching {
            getSystemService(DisplayManager::class.java)
        }.getOrNull() ?: return

        displayManager = manager

        val listener = object : DisplayManager.DisplayListener {
            override fun onDisplayAdded(displayId: Int) = refreshLegacyState()
            override fun onDisplayRemoved(displayId: Int) = refreshLegacyState()
            override fun onDisplayChanged(displayId: Int) = refreshLegacyState()
        }

        runCatching { manager.registerDisplayListener(listener, null) }
            .onSuccess { displayListener = listener }

        refreshLegacyState()
    }

    private fun refreshLegacyState() {
        onCaptureStateChanged(hasCaptureDisplay())
    }

    /**
     * True when a display exists that looks like a capture surface: present in
     * the full display list, not the built-in screen, and not advertising itself
     * as a presentation target the way real external screens do.
     */
    private fun hasCaptureDisplay(): Boolean {
        val manager = displayManager ?: return false

        val all = runCatching { manager.displays }.getOrNull() ?: return false
        val presentation = runCatching {
            manager.getDisplays(DisplayManager.DISPLAY_CATEGORY_PRESENTATION)
        }.getOrNull().orEmpty().map { it.displayId }.toSet()

        return all.any { display ->
            display.displayId != Display.DEFAULT_DISPLAY &&
                display.displayId !in presentation &&
                display.state != Display.STATE_OFF
        }
    }

    private fun onCaptureStateChanged(captured: Boolean) {
        if (captured == isCaptured) return
        isCaptured = captured

        runOnUiThread {
            applySecure(captured)
            eventSink?.success(captured)
        }
    }

    private fun applySecure(secure: Boolean) {
        runCatching {
            if (secure) {
                window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
            } else {
                window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
            }
        }
    }

    private companion object {
        const val CHANNEL = "com.tareeqalmajd.studentapp/screen_guard"
    }
}
