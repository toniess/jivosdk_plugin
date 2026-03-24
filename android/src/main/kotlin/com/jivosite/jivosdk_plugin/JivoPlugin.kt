package com.jivosite.jivosdk_plugin

import android.content.Context

import android.app.Activity
import android.app.LocaleManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.LocaleList
import android.os.Looper
import androidx.annotation.RequiresApi
import androidx.appcompat.app.AppCompatDelegate
import androidx.core.os.LocaleListCompat
import com.jivosite.sdk.ui.chat.JivoChatActivity
import com.jivosite.sdk.Jivo
import com.jivosite.sdk.support.builders.ContactInfo
import com.jivosite.sdk.model.pojo.CustomData
import com.jivosite.sdk.model.repository.history.*
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodChannel.Result
import com.jivosite.sdk.support.builders.Config
import org.json.JSONArray
import org.json.JSONObject


/** JivoPlatform */
class JivoPlugin : FlutterPlugin, ActivityAware, MethodCallHandler {

    private var applicationContext: Context? = null
    private lateinit var channel: MethodChannel
    private var mainActivity: Activity? = null
    private var newMessageListener: NewMessageListener? = null
    private val handler = Handler(Looper.getMainLooper())
    private val jivoConfigBuilder: Config.Builder = Config.Builder()

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = flutterPluginBinding.applicationContext.also {
            Jivo.init(it)
        }
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "jivosdk_plugin")
        channel.setMethodCallHandler(this)

        Jivo.addNewMessageListener(object : NewMessageListener {
            override fun onNewMessage(hasUnread: Boolean) {
                handler.post {
                    channel.invokeMethod("session:updateUnreadCounter(number)", if (hasUnread) 1 else 0)
                }
            }
        }.apply {
            newMessageListener = this
        })
    }


    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        mainActivity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        mainActivity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        mainActivity = binding.activity
    }

    override fun onDetachedFromActivity() {
        mainActivity = null
    }

    @RequiresApi(Build.VERSION_CODES.M)
    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "session:setup" -> {
                val data = call.arguments as Map<String, String>
                val widgetId = data["channel_id"] ?: ""
                val userToken = data["user_token"] ?: ""
                if (widgetId.contains('/')) {
                    val list = widgetId.split('/')
                    Jivo.setData(widgetId = list.last(), userToken = userToken, host = list.first())
                } else {
                    Jivo.setData(widgetId = widgetId, userToken = userToken)
                }
                result.success(null)
            }

            "notification:setPushToken" -> {
                val token = call.arguments as String
                if (token.isNotBlank()) {
                    Jivo.updatePushToken(call.arguments as String)
                }
                result.success(null)
            }

            "session:setContactInfo" -> {
                val contactInfo = call.arguments as Map<String, String>
                Jivo.setContactInfo(ContactInfo.contactInfo {
                    name = contactInfo["name"]
                    email = contactInfo["email"] ?: ""
                    phone = contactInfo["phone"] ?: ""
                    description = contactInfo["brief"] ?: ""
                })
                result.success(null)
            }

            "session:setCustomData" -> {
                val arguments = call.arguments as String
                val argumentsJSONArray = JSONArray(arguments)
                val customDataFields = arrayListOf<CustomData>()
                (0 until argumentsJSONArray.length()).forEach { index ->
                    argumentsJSONArray.getJSONObject(index)?.let {
                        customDataFields.add(
                            CustomData(
                                it.getValue("content"),
                                it.getValue("title"),
                                it.getValue("link"),
                                it.getValue("key"),
                            )
                        )
                    }
                }
                Jivo.setCustomData(customDataFields)
                result.success(null)
            }

            "display:present" -> {
                Intent(mainActivity, JivoChatActivity::class.java).apply {
                    if (mainActivity?.packageManager?.let { resolveActivity(it) } != null) {
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        applicationContext?.startActivity(this)
                    }
                }
                result.success(null)
            }

            "session:clear" -> {
                Jivo.clear()
                result.success(null)
            }

            "display:defineText" -> {
                val defineText = call.arguments as? Map<String, String>
                defineText?.forEach {
                    when (it.key) {
                        "headerTitle" -> jivoConfigBuilder.setTitleString(it.value)
                        "headerSubtitle" -> jivoConfigBuilder.setSubtitleString(it.value)
                        "messageWelcome" -> jivoConfigBuilder.setWelcomeMessageString(it.value)
                        "messageOffline" -> jivoConfigBuilder.setOfflineMessageString(it.value)
                    }
                }
                setJivoConfigBuilder(jivoConfigBuilder)
                result.success(null)
            }

            "display:setLocale" -> {
                val languageTag = call.arguments as? String
                if (!languageTag.isNullOrBlank()) {
                    Jivo.setLocale(languageTag)
                }
                result.success(null)
            }

            "display:setThemeMode" -> {
                val mode = (call.arguments as String).lowercase()
                AppCompatDelegate.setDefaultNightMode(
                    when(mode) {
                        "light" -> AppCompatDelegate.MODE_NIGHT_NO
                        "dark" -> AppCompatDelegate.MODE_NIGHT_YES
                        else -> AppCompatDelegate.MODE_NIGHT_FOLLOW_SYSTEM
                    }
                )
                result.success(null)
            }

            else -> result.success(null)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        applicationContext = null
        newMessageListener = null
    }

    private fun setJivoConfigBuilder(jivoConfigBuilder: Config.Builder) {
        Jivo.setConfig(jivoConfigBuilder.build())
    }

    private fun JSONObject.getValue(name: String): String {
        return if (this.has(name)) this.get(name).toString() else ""
    }

}