package com.itech.storemanagement

import android.content.SharedPreferences
import android.provider.Settings
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKeys
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Phase K (D5): exposes the Android SSAID (Settings.Secure.ANDROID_ID) to the
 * Dart [AndroidDeviceIdentityProvider] through the `itech.app/device_identity`
 * channel. The raw value is used ONLY as a fingerprint input on the Dart side
 * (salted SHA-256) — it is never transmitted, logged, or persisted.
 *
 * SSAID is scoped per app-signing key + user + device: stable across restarts
 * and updates of THIS app, distinct across different physical devices.
 */
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            DEVICE_IDENTITY_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                METHOD_GET_SSAID -> {
                    try {
                        val ssaid = Settings.Secure.getString(
                            contentResolver,
                            Settings.Secure.ANDROID_ID
                        )
                        // Null (unavailable) is passed through so Dart applies
                        // its explicit sentinel fallback.
                        result.success(ssaid)
                    } catch (_: Exception) {
                        result.success(null)
                    }
                }
                else -> result.notImplemented()
            }
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SECURE_STORAGE_CHANNEL
        ).setMethodCallHandler { call, result ->
            val prefs = securePrefsOrNull()
            if (prefs == null) {
                // Fail-closed: no plaintext fallback is ever used (Phase K D7).
                result.error("SECURE_STORAGE_UNAVAILABLE", "Keystore-backed storage could not be initialized", null)
                return@setMethodCallHandler
            }
            when (call.method) {
                METHOD_SECURE_READ -> {
                    val key = call.argument<String>("key")
                    if (key == null) {
                        result.error("SECURE_STORAGE_BAD_ARGS", "missing key", null)
                    } else {
                        try {
                            result.success(prefs.getString(key, null))
                        } catch (e: Exception) {
                            result.error("SECURE_STORAGE_READ_FAILED", e.message, null)
                        }
                    }
                }
                METHOD_SECURE_WRITE -> {
                    val key = call.argument<String>("key")
                    val value = call.argument<String>("value")
                    if (key == null || value == null) {
                        result.error("SECURE_STORAGE_BAD_ARGS", "missing key or value", null)
                    } else {
                        try {
                            prefs.edit().putString(key, value).apply()
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("SECURE_STORAGE_WRITE_FAILED", e.message, null)
                        }
                    }
                }
                METHOD_SECURE_DELETE -> {
                    val key = call.argument<String>("key")
                    if (key == null) {
                        result.error("SECURE_STORAGE_BAD_ARGS", "missing key", null)
                    } else {
                        try {
                            prefs.edit().remove(key).apply()
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("SECURE_STORAGE_DELETE_FAILED", e.message, null)
                        }
                    }
                }
                METHOD_SECURE_CONTAINS -> {
                    val key = call.argument<String>("key")
                    if (key == null) {
                        result.error("SECURE_STORAGE_BAD_ARGS", "missing key", null)
                    } else {
                        try {
                            result.success(prefs.contains(key))
                        } catch (e: Exception) {
                            result.error("SECURE_STORAGE_READ_FAILED", e.message, null)
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    /**
     * Phase K (D7): Keystore-backed secret persistence backing the
     * `itech.app/secure_storage` channel. Values are stored in
     * EncryptedSharedPreferences (pref keys AES256-SIV, values AES256-GCM)
     * whose master key lives in the Android Keystore — nothing sensitive is
     * ever written in plaintext. Returns null when secure initialization is
     * impossible so callers fail closed instead of degrading to plaintext.
     */
    private fun securePrefsOrNull(): SharedPreferences? {
        return try {
            val masterKeyAlias = MasterKeys.getOrCreate(MasterKeys.AES256_GCM_SPEC)
            EncryptedSharedPreferences.create(
                "itech_secure_prefs",
                masterKeyAlias,
                applicationContext,
                EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
            )
        } catch (_: Throwable) {
            // Throwable, not Exception: on API < 23 the security-crypto
            // classes may fail to load (VerifyError/NoClassDefFoundError).
            // Any such failure must fail CLOSED — no plaintext fallback.
            null
        }
    }

    companion object {
        const val DEVICE_IDENTITY_CHANNEL = "itech.app/device_identity"
        const val METHOD_GET_SSAID = "getSsaid"
        const val SECURE_STORAGE_CHANNEL = "itech.app/secure_storage"
        const val METHOD_SECURE_READ = "read"
        const val METHOD_SECURE_WRITE = "write"
        const val METHOD_SECURE_DELETE = "delete"
        const val METHOD_SECURE_CONTAINS = "containsKey"
    }
}
